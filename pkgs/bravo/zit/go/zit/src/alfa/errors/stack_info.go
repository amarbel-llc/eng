package errors

import (
	"fmt"
	"path/filepath"
	"runtime"
	"strings"

	"code.linenisgreat.com/zit/go/zit/src/alfa/stack_frame"
)

//go:noinline
func MustStackFrame(skip int) stack_frame.Frame {
	frame, ok := MakeStackFrame(skip + 1)

	if !ok {
		panic("stack unavailable")
	}

	return frame
}

//go:noinline
func MakeStackFrames(skip, count int) (frames []stack_frame.Frame) {
	programCounters := make([]uintptr, count)
	writtenCounters := runtime.Callers(skip+1, programCounters) // 0 is self
	if writtenCounters == 0 {
		return
	}

	programCounters = programCounters[:writtenCounters]

	rawFrames := runtime.CallersFrames(programCounters)

	frames = make([]stack_frame.Frame, 0, len(programCounters))

	for {
		frame, more := rawFrames.Next()
		frames = append(frames, stack_frame.MakeFrameFromRuntimeFrame(frame))

		if !more {
			break
		}
	}

	return
}

//go:noinline
func MakeStackFrame(skip int) (si stack_frame.Frame, ok bool) {
	var programCounter uintptr
	programCounter, _, _, ok = runtime.Caller(skip + 1) // 0 is self

	if !ok {
		return
	}

	frames := runtime.CallersFrames([]uintptr{programCounter})

	frame, _ := frames.Next()
	si = stack_frame.MakeFrameFromRuntimeFrame(frame)

	// TODO remove this ugly hack
	if si.Function == "Wrap" {
		panic(fmt.Sprintf("Parent Wrap included in stack. Skip: %d", skip))
	}

	return
}

func getPackageAndFunctionName(v string) (p string, f string) {
	p, f = filepath.Split(v)

	idx := strings.Index(f, ".")

	if idx == -1 {
		return
	}

	p += f[:idx]

	if len(f) > idx+1 {
		f = f[idx+1:]
	}

	return
}

type stackWrapError struct {
	ExtraData string
	stack_frame.Frame
	error

	next *stackWrapError
}

func (se *stackWrapError) Unwrap() error {
	if se.next == nil {
		return se.error
	} else {
		return se.next.Unwrap()
	}
}

func (se *stackWrapError) UnwrapAll() []error {
	switch {
	case se.next != nil && se.error != nil:
		return []error{se.error, se.next}

	case se.next != nil:
		return []error{se.next}

	case se.error != nil:
		return []error{se.error}

	default:
		return nil
	}
}

func (se *stackWrapError) writeError(sb *strings.Builder) {
	sb.WriteString(se.Frame.String())

	if se.error != nil {
		sb.WriteString(": ")
		sb.WriteString(se.error.Error())
	}

	if se.next != nil {
		sb.WriteString("\n")
		se.next.writeError(sb)
	}

	if se.next == nil && se.error == nil {
		sb.WriteString("zit/alfa/errors/stackWrapError: both next and error are nil.")
		sb.WriteString("zit/alfa/errors/stackWrapError: this usually means that some nil error was wrapped in the error stack.")
	}
}

func (se *stackWrapError) writeErrorNoStack(sb *strings.Builder) {
	if se.ExtraData != "" {
		fmt.Fprintf(sb, "- %s\n", se.ExtraData)
	}

	if se.error != nil {
		fmt.Fprintf(sb, "- %s\n", se.error.Error())
	}

	if se.next != nil {
		se.next.writeErrorNoStack(sb)
	}

	if se.next == nil && se.error == nil {
		sb.WriteString("zit/alfa/errors/stackWrapError: both next and error are nil.")
		sb.WriteString("zit/alfa/errors/stackWrapError: this usually means that some nil error was wrapped in the error stack.")
	}
}

func (se *stackWrapError) Error() string {
	sb := &strings.Builder{}
	se.writeError(sb)
	return sb.String()
}
