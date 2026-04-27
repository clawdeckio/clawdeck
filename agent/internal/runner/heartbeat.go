package runner

import (
	"context"
	"log"
	"runtime"
	"time"

	"github.com/mojomast/uberclawcontrol/agent/internal/clawdeck"
)

type HeartbeatRunner struct {
	client     *clawdeck.Client
	interval   time.Duration
	agentID    int64
	lastStatus string
}

func NewHeartbeatRunner(client *clawdeck.Client, agentID int64, interval time.Duration) *HeartbeatRunner {
	if interval == 0 {
		interval = 30 * time.Second
	}
	return &HeartbeatRunner{
		client:   client,
		interval: interval,
		agentID:  agentID,
	}
}

func (h *HeartbeatRunner) Run(ctx context.Context) error {
	ticker := time.NewTicker(h.interval)
	defer ticker.Stop()

	h.sendHeartbeat(ctx)

	for {
		select {
		case <-ctx.Done():
			log.Printf("heartbeat runner stopping: %v", ctx.Err())
			return ctx.Err()
		case <-ticker.C:
			h.sendHeartbeat(ctx)
		}
	}
}

func (h *HeartbeatRunner) sendHeartbeat(ctx context.Context) {
	metadata := h.collectMetadata()
	status := "online"
	if h.lastStatus != "" {
		status = h.lastStatus
	}

	resp, err := h.client.Heartbeat(h.agentID, status, metadata)
	if err != nil {
		log.Printf("heartbeat failed: %v", err)
		return
	}

	log.Printf("heartbeat ok: agent status=%s desired_state=%s", 
		resp.Agent.Status, resp.DesiredState.Action)

	if resp.DesiredState.Action != "" && resp.DesiredState.Action != "none" {
		log.Printf("desired state action: %s", resp.DesiredState.Action)
	}
}

func (h *HeartbeatRunner) collectMetadata() map[string]any {
	var memStats runtime.MemStats
	runtime.ReadMemStats(&memStats)

	return map[string]any{
		"goroutines":   runtime.NumGoroutine(),
		"go_version":   runtime.Version(),
		"alloc_mb":     memStats.Alloc / 1024 / 1024,
		"sys_mb":       memStats.Sys / 1024 / 1024,
		"num_cpu":      runtime.NumCPU(),
	}
}

func (h *HeartbeatRunner) SetStatus(status string) {
	h.lastStatus = status
}
