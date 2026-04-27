package runner

import (
	"context"

	"github.com/mojomast/uberclawcontrol/agent/internal/clawdeck"
)

type Executor interface {
	Execute(ctx context.Context, task *clawdeck.Task) ExecutionResult
}

type ExecutionResult struct {
	Completed bool
	Error     error
	Output    string
}

type StubExecutor struct{}

func (s *StubExecutor) Execute(ctx context.Context, task *clawdeck.Task) ExecutionResult {
	return ExecutionResult{
		Completed: true,
		Output:    "stub execution completed",
	}
}
