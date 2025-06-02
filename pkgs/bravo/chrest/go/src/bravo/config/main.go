package config

import (
	"bufio"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"path"
	"path/filepath"

	"code.linenisgreat.com/zit/go/zit/src/alfa/errors"
	"code.linenisgreat.com/zit/go/zit/src/echo/fd"
)

type Config struct {
	DefaultBrowser BrowserId   `json:"default-browser"`
	LoadedBrowsers []BrowserId `json:"-"`
	Home           string      `json:"-"`
}

func (c Config) ServerPath() string {
	return filepath.Join(c.Home, ".local", "bin", "chrest")
}

func StateDirectory() (v string, err error) {
	v = os.Getenv("XDG_STATE_HOME")

	if v == "" {
		if v, err = os.UserHomeDir(); err != nil {
			err = errors.Wrap(err)
			return
		}

		v = path.Join(v, ".local", "state")
	}

	v = path.Join(v, "chrest")

	return
}

func (c Config) GetSocketPathForBrowserId(
	id BrowserId,
) (sock string, err error) {
	if id.IsEmpty() {
		id = c.DefaultBrowser
	}

	var stateDir string

	if stateDir, err = StateDirectory(); err != nil {
		err = errors.Wrap(err)
		return
	}

	sock = path.Join(stateDir, fmt.Sprintf("%s.sock", id))

	return
}

func (c Config) GetAllSockets() (socks []string, err error) {
	var stateDir string

	if stateDir, err = StateDirectory(); err != nil {
		err = errors.Wrap(err)
		return
	}

	if socks, err = filepath.Glob(filepath.Join(stateDir, "*.sock")); err != nil {
		err = errors.Wrap(err)
		return
	}

	return
}

func (c Config) Directory() (v string) {
	v = os.Getenv("XDG_CONFIG_HOME")

	if v == "" {
		v = path.Join(c.Home, ".config")
	}

	v = path.Join(v, "chrest")

	return
}

func (c *Config) Read() (err error) {
	wg := errors.MakeWaitGroupParallel()

	wg.Do(c.readConfig)
	wg.Do(c.readLoadedBrowsers)

	if err = wg.GetError(); err != nil {
		err = errors.Wrap(err)
		return
	}

	return
}

func (c *Config) readConfig() (err error) {
	if c.Home, err = os.UserHomeDir(); err != nil {
		err = errors.Wrap(err)
		return
	}

	p := path.Join(c.Directory(), "config.json")

	var f *os.File

	if f, err = os.Open(p); err != nil {
		if errors.IsNotExist(err) {
			err = nil
		} else {
			err = errors.Wrap(err)
		}

		return
	}

	defer errors.DeferredCloser(&err, f)

	dec := json.NewDecoder(bufio.NewReader(f))

	if err = dec.Decode(c); err != nil {
		err = errors.Wrap(err)
		return
	}

	return
}

func (c *Config) readLoadedBrowsers() (err error) {
	var loadedBrowserPaths []string

	var stateDir string

	if stateDir, err = StateDirectory(); err != nil {
		err = errors.Wrap(err)
		return
	}

	if loadedBrowserPaths, err = filepath.Glob(filepath.Join(stateDir, "*.sock")); err != nil {
		err = errors.Wrap(err)
		return
	}

	for _, loadedBrowserPath := range loadedBrowserPaths {
		var id BrowserId

		if err = id.Set(fd.FileNameSansExt(loadedBrowserPath)); err != nil {
			err = errors.Wrap(err)
			return
		}

		c.LoadedBrowsers = append(c.LoadedBrowsers, id)
	}

	return
}

func (c *Config) Write() (err error) {
	dir := c.Directory()
	p := path.Join(dir, "config.json")

	var f *os.File

	if f, err = os.CreateTemp("", ""); err != nil {
		err = errors.Wrap(err)
		return
	}

	defer f.Close()

	w := bufio.NewWriter(f)

	enc := json.NewEncoder(w)

	if err = enc.Encode(c); err != nil {
		err = errors.Wrap(err)
		return
	}

	if err = w.Flush(); err != nil {
		err = errors.Wrap(err)
		return
	}

	log.Print(f.Name(), p)

	if err = os.MkdirAll(dir, 0o700); err != nil {
		err = errors.Wrap(err)
		return
	}

	if err = os.Rename(f.Name(), p); err != nil {
		err = errors.Wrap(err)
		return
	}

	return
}
