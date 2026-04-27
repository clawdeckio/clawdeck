package config

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"time"
)

const (
	DefaultAPIURL         = "http://localhost:3000"
	DefaultHeartbeatDelay = 30 * time.Second
	DefaultTaskPollDelay  = 5 * time.Second
	DefaultCommandPollDelay = 5 * time.Second
	TokenFilePermissions  = 0600
)

type Config struct {
	APIURL           string
	JoinToken        string
	AgentTokenPath   string
	HeartbeatDelay   time.Duration
	TaskPollDelay    time.Duration
	CommandPollDelay time.Duration
	AgentInfo        AgentInfo
}

type AgentInfo struct {
	Name     string            `json:"name"`
	Hostname string            `json:"hostname"`
	HostUID  string            `json:"host_uid"`
	Platform string            `json:"platform"`
	Version  string            `json:"version"`
	Tags     []string          `json:"tags"`
	Metadata map[string]string `json:"metadata"`
}

type persistedToken struct {
	AgentID    int64  `json:"agent_id"`
	Token      string `json:"token"`
	StoredAt   string `json:"stored_at"`
}

func Load() (*Config, error) {
	cfg := &Config{
		APIURL:           getEnv("CLAWDECK_API_URL", DefaultAPIURL),
		JoinToken:        os.Getenv("CLAWDECK_JOIN_TOKEN"),
		AgentTokenPath:   getEnv("CLAWDECK_AGENT_TOKEN_PATH", ""),
		HeartbeatDelay:   DefaultHeartbeatDelay,
		TaskPollDelay:    DefaultTaskPollDelay,
		CommandPollDelay: DefaultCommandPollDelay,
		AgentInfo: AgentInfo{
			Name:     getEnv("CLAWDECK_AGENT_NAME", "claw-agent"),
			Hostname: getEnv("CLAWDECK_HOSTNAME", ""),
			HostUID:  getEnv("CLAWDECK_HOST_UID", ""),
			Platform: getEnv("CLAWDECK_PLATFORM", ""),
			Version:  getEnv("CLAWDECK_VERSION", "0.1.0"),
		},
	}

	if cfg.AgentInfo.Hostname == "" {
		if h, err := os.Hostname(); err == nil {
			cfg.AgentInfo.Hostname = h
		}
	}

	return cfg, nil
}

func (c *Config) LoadPersistedToken() (agentID int64, token string, err error) {
	if c.AgentTokenPath == "" {
		return 0, "", nil
	}

	data, err := os.ReadFile(c.AgentTokenPath)
	if err != nil {
		if os.IsNotExist(err) {
			return 0, "", nil
		}
		return 0, "", fmt.Errorf("reading token file: %w", err)
	}

	var pt persistedToken
	if err := json.Unmarshal(data, &pt); err != nil {
		return 0, "", fmt.Errorf("parsing token file: %w", err)
	}

	return pt.AgentID, pt.Token, nil
}

func (c *Config) SaveToken(agentID int64, token string) error {
	if c.AgentTokenPath == "" {
		return nil
	}

	pt := persistedToken{
		AgentID:  agentID,
		Token:    token,
		StoredAt: time.Now().UTC().Format(time.RFC3339),
	}

	data, err := json.MarshalIndent(pt, "", "  ")
	if err != nil {
		return fmt.Errorf("marshaling token: %w", err)
	}

	dir := filepath.Dir(c.AgentTokenPath)
	if err := os.MkdirAll(dir, 0700); err != nil {
		return fmt.Errorf("creating token directory: %w", err)
	}

	if err := os.WriteFile(c.AgentTokenPath, data, TokenFilePermissions); err != nil {
		return fmt.Errorf("writing token file: %w", err)
	}

	return nil
}

func (c *Config) ClearToken() error {
	if c.AgentTokenPath == "" {
		return nil
	}

	if err := os.Remove(c.AgentTokenPath); err != nil && !os.IsNotExist(err) {
		return fmt.Errorf("removing token file: %w", err)
	}
	return nil
}

func getEnv(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}
