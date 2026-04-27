package orchestrator

import (
	"context"
	"log"
	"time"

	"github.com/mojomast/uberclawcontrol/agent/internal/clawdeck"
)

type CommandRunner struct {
	client   *clawdeck.Client
	interval time.Duration
	handlers map[string]CommandHandler
}

type CommandHandler func(ctx context.Context, cmd *clawdeck.Command) map[string]any

func NewCommandRunner(client *clawdeck.Client, interval time.Duration) *CommandRunner {
	if interval == 0 {
		interval = 5 * time.Second
	}
	cr := &CommandRunner{
		client:   client,
		interval: interval,
		handlers: make(map[string]CommandHandler),
	}
	cr.registerDefaultHandlers()
	return cr
}

func (c *CommandRunner) Run(ctx context.Context) error {
	ticker := time.NewTicker(c.interval)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			log.Printf("command runner stopping: %v", ctx.Err())
			return ctx.Err()
		case <-ticker.C:
			c.pollAndHandle(ctx)
		}
	}
}

func (c *CommandRunner) pollAndHandle(ctx context.Context) {
	cmd, err := c.client.GetNextCommand()
	if err != nil {
		log.Printf("failed to get next command: %v", err)
		return
	}

	if cmd == nil {
		return
	}

	log.Printf("received command id=%d kind=%s state=%s", cmd.ID, cmd.Kind, cmd.State)

	_, err = c.client.AckCommand(cmd.ID)
	if err != nil {
		log.Printf("failed to ack command %d: %v", cmd.ID, err)
		return
	}
	log.Printf("acknowledged command id=%d", cmd.ID)

	result := c.dispatch(ctx, cmd)

	_, err = c.client.CompleteCommand(cmd.ID, result)
	if err != nil {
		log.Printf("failed to complete command %d: %v", cmd.ID, err)
		return
	}
	log.Printf("completed command id=%d", cmd.ID)
}

func (c *CommandRunner) dispatch(ctx context.Context, cmd *clawdeck.Command) map[string]any {
	handler, ok := c.handlers[cmd.Kind]
	if !ok {
		log.Printf("no handler for command kind=%s", cmd.Kind)
		return map[string]any{"success": false, "error": "unknown command kind"}
	}

	return handler(ctx, cmd)
}

func (c *CommandRunner) RegisterHandler(kind string, handler CommandHandler) {
	c.handlers[kind] = handler
}

func (c *CommandRunner) registerDefaultHandlers() {
	c.RegisterHandler("drain", HandleDrain)
	c.RegisterHandler("resume", HandleResume)
	c.RegisterHandler("restart", HandleRestart)
	c.RegisterHandler("upgrade", HandleUpgrade)
}
