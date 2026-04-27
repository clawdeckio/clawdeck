package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/mojomast/uberclawcontrol/agent/internal/clawdeck"
	"github.com/mojomast/uberclawcontrol/agent/internal/config"
	"github.com/mojomast/uberclawcontrol/agent/internal/orchestrator"
	"github.com/mojomast/uberclawcontrol/agent/internal/runner"
)

var (
	version = "dev"
)

func main() {
	showVersion := flag.Bool("version", false, "show version")
	flag.Parse()

	if *showVersion {
		fmt.Printf("claw-agent %s\n", version)
		os.Exit(0)
	}

	log.Printf("claw-agent %s starting", version)

	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("failed to load config: %v", err)
	}

	client := clawdeck.NewClient(cfg.APIURL)

	agentID, token, err := cfg.LoadPersistedToken()
	if err != nil {
		log.Printf("warning: failed to load persisted token: %v", err)
	}

	if token == "" && cfg.JoinToken == "" {
		log.Fatal("no persisted token found and CLAWDECK_JOIN_TOKEN not set")
	}

	if token != "" {
		client.SetToken(token)
		client.SetAgentID(agentID)
		log.Printf("using persisted token for agent %d", agentID)
	} else {
		log.Printf("registering agent with join token")
		resp, err := client.Register(cfg.JoinToken, clawdeck.AgentInfo{
			Name:     cfg.AgentInfo.Name,
			Hostname: cfg.AgentInfo.Hostname,
			HostUID:  cfg.AgentInfo.HostUID,
			Platform: cfg.AgentInfo.Platform,
			Version:  version,
			Tags:     cfg.AgentInfo.Tags,
			Metadata: cfg.AgentInfo.Metadata,
		})
		if err != nil {
			log.Fatalf("failed to register: %v", err)
		}

		agentID = resp.Agent.ID
		log.Printf("registered agent id=%d name=%s", resp.Agent.ID, resp.Agent.Name)

		if err := cfg.SaveToken(resp.Agent.ID, resp.AgentToken); err != nil {
			log.Printf("warning: failed to persist token: %v", err)
		}
	}

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		sig := <-sigChan
		log.Printf("received signal %v, shutting down", sig)
		cancel()
	}()

	heartbeatRunner := runner.NewHeartbeatRunner(client, agentID, cfg.HeartbeatDelay)
	taskRunner := runner.NewTaskRunner(client, cfg.TaskPollDelay, runner.NewStubExecutor())
	commandRunner := orchestrator.NewCommandRunner(client, cfg.CommandPollDelay)

	errChan := make(chan error, 3)

	go func() {
		if err := heartbeatRunner.Run(ctx); err != nil && err != context.Canceled {
			errChan <- fmt.Errorf("heartbeat: %w", err)
		}
	}()

	go func() {
		if err := taskRunner.Run(ctx); err != nil && err != context.Canceled {
			errChan <- fmt.Errorf("task: %w", err)
		}
	}()

	go func() {
		if err := commandRunner.Run(ctx); err != nil && err != context.Canceled {
			errChan <- fmt.Errorf("command: %w", err)
		}
	}()

	select {
	case <-ctx.Done():
		log.Printf("shutting down")
	case err := <-errChan:
		log.Printf("runner error: %v", err)
		cancel()
	}

	log.Printf("claw-agent stopped")
}
