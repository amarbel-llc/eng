package main

import (
	"flag"
	"os"

	"code.linenisgreat.com/chrest/go/src/alfa/browser"
	"code.linenisgreat.com/chrest/go/src/alfa/symlink"
	"code.linenisgreat.com/chrest/go/src/bravo/config"
	"code.linenisgreat.com/chrest/go/src/charlie/install"
	"code.linenisgreat.com/zit/go/zit/src/alfa/errors"
)

func CmdInit() (err error) {
	var (
		initConfig config.Config
		idsChrome  install.IdSet
		idsFirefox install.IdSet
	)

	flag.Var(
		&initConfig.DefaultBrowser,
		"browser",
		"the browser to use by default",
	)

	idsChrome.Browser = browser.Chrome
	idsFirefox.Browser = browser.Firefox

	flag.Var(
		&idsChrome,
		"chrome",
		"the chrome IDs to install for",
	)

	flag.Var(
		&idsFirefox,
		"firefox",
		"the Firefox IDs to install for",
	)

	if initConfig, err = config.Default(); err != nil {
		err = errors.Wrap(err)
		return
	}

	flag.Parse()

	// TODO do not overwrite config if it exists
	if err = initConfig.Write(); err != nil {
		err = errors.Wrap(err)
		return
	}

	var exe string
	if exe, err = os.Executable(); err != nil {
		err = errors.Wrap(err)
		return
	}

	err = nil

	newPath := initConfig.ServerPath()

	if err = symlink.Symlink(exe, newPath); err != nil {
		err = errors.Wrap(err)
		return
	}

	for _, is := range []install.IdSet{idsChrome, idsFirefox} {
		if _, _, err = is.Install(
			initConfig,
		); err != nil {
			err = errors.Wrap(err)
			return
		}
	}

	return
}
