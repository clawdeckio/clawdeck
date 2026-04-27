package runner

import (
	"context"
	"log"
	"time"

	"github.com/mojomast/uberclawcontrol/agent/internal/clawdeck"
)

type TaskRunner struct {
	client   *clawdeck.Client
	interval time.Duration
	executor Executor
}

func NewTaskRunner(client *clawdeck.Client, interval time.Duration, executor Executor) *TaskRunner {
	if interval == 0 {
		interval = 5 * time.Second
	}
	if executor == nil {
		executor = &StubExecutor{}
	}
	return &TaskRunner{
		client:   client,
		interval: interval,
		executor: executor,
	}
}

func (t *TaskRunner) Run(ctx context.Context) error {
	ticker := time.NewTicker(t.interval)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			log.Printf("task runner stopping: %v", ctx.Err())
			return ctx.Err()
		case <-ticker.C:
			t.pollAndExecute(ctx)
		}
	}
}

func (t *TaskRunner) pollAndExecute(ctx context.Context) {
	task, err := t.client.GetNextTask()
	if err != nil {
		log.Printf("failed to get next task: %v", err)
		return
	}

	if task == nil {
		return
	}

	log.Printf("received task id=%d name=%q status=%s", task.ID, task.Name, task.Status)

	if task.ClaimedByAgentID == nil {
		claimed, err := t.client.ClaimTask(task.ID)
		if err != nil {
			log.Printf("failed to claim task %d: %v", task.ID, err)
			return
		}
		task = claimed
		log.Printf("claimed task id=%d", task.ID)
	}

	result := t.executor.Execute(ctx, task)

	if result.Error != nil {
		log.Printf("task %d execution failed: %v", task.ID, result.Error)
		return
	}

	if result.Completed {
		_, err = t.client.CompleteTask(task.ID)
		if err != nil {
			log.Printf("failed to complete task %d: %v", task.ID, err)
			return
		}
		log.Printf("task %d completed", task.ID)
	}
}


