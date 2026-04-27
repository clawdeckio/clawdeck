package clawdeck

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
)

type Client struct {
	baseURL    string
	httpClient *http.Client
	token      string
	agentID    int64
}

func NewClient(baseURL string) *Client {
	return &Client{
		baseURL: baseURL,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

func (c *Client) SetToken(token string) {
	c.token = token
}

func (c *Client) SetAgentID(id int64) {
	c.agentID = id
}

func (c *Client) AgentID() int64 {
	return c.agentID
}

func (c *Client) Register(joinToken string, info AgentInfo) (*RegisterResponse, error) {
	req := RegisterRequest{
		JoinToken: joinToken,
		Agent:     info,
	}

	var resp RegisterResponse
	if err := c.doRequest("POST", "/api/v1/agents/register", req, &resp, false); err != nil {
		return nil, fmt.Errorf("register: %w", err)
	}

	c.token = resp.AgentToken
	c.agentID = resp.Agent.ID

	return &resp, nil
}

func (c *Client) Heartbeat(agentID int64, status string, metadata map[string]any) (*HeartbeatResponse, error) {
	req := HeartbeatRequest{
		Status:   status,
		Metadata: metadata,
	}

	var resp HeartbeatResponse
	path := fmt.Sprintf("/api/v1/agents/%d/heartbeat", agentID)
	if err := c.doRequest("POST", path, req, &resp, true); err != nil {
		return nil, fmt.Errorf("heartbeat: %w", err)
	}

	return &resp, nil
}

func (c *Client) GetNextTask() (*Task, error) {
	var resp Task
	if err := c.doRequest("GET", "/api/v1/tasks/next", nil, &resp, true); err != nil {
		if isNoContent(err) {
			return nil, nil
		}
		return nil, fmt.Errorf("get next task: %w", err)
	}
	return &resp, nil
}

func (c *Client) ClaimTask(taskID int64) (*Task, error) {
	var resp Task
	path := fmt.Sprintf("/api/v1/tasks/%d/claim", taskID)
	if err := c.doRequest("PATCH", path, nil, &resp, true); err != nil {
		return nil, fmt.Errorf("claim task: %w", err)
	}
	return &resp, nil
}

func (c *Client) UpdateTask(taskID int64, updates TaskUpdateRequest) (*Task, error) {
	var resp Task
	path := fmt.Sprintf("/api/v1/tasks/%d", taskID)
	if err := c.doRequest("PATCH", path, updates, &resp, true); err != nil {
		return nil, fmt.Errorf("update task: %w", err)
	}
	return &resp, nil
}

func (c *Client) CompleteTask(taskID int64) (*Task, error) {
	var resp Task
	path := fmt.Sprintf("/api/v1/tasks/%d/complete", taskID)
	if err := c.doRequest("PATCH", path, nil, &resp, true); err != nil {
		return nil, fmt.Errorf("complete task: %w", err)
	}
	return &resp, nil
}

func (c *Client) GetNextCommand() (*Command, error) {
	var resp Command
	if err := c.doRequest("GET", "/api/v1/agent_commands/next", nil, &resp, true); err != nil {
		if isNoContent(err) {
			return nil, nil
		}
		return nil, fmt.Errorf("get next command: %w", err)
	}
	return &resp, nil
}

func (c *Client) AckCommand(commandID int64) (*Command, error) {
	var resp Command
	path := fmt.Sprintf("/api/v1/agent_commands/%d/ack", commandID)
	if err := c.doRequest("PATCH", path, CommandAckRequest{}, &resp, true); err != nil {
		return nil, fmt.Errorf("ack command: %w", err)
	}
	return &resp, nil
}

func (c *Client) CompleteCommand(commandID int64, result map[string]any) (*Command, error) {
	req := CommandCompleteRequest{Result: result}
	var resp Command
	path := fmt.Sprintf("/api/v1/agent_commands/%d/complete", commandID)
	if err := c.doRequest("PATCH", path, req, &resp, true); err != nil {
		return nil, fmt.Errorf("complete command: %w", err)
	}
	return &resp, nil
}

type noContentError struct{}

func (e *noContentError) Error() string {
	return "no content"
}

func isNoContent(err error) bool {
	_, ok := err.(*noContentError)
	return ok
}

func (c *Client) doRequest(method, path string, body any, out any, requireAuth bool) error {
	var reqBody io.Reader
	if body != nil {
		data, err := json.Marshal(body)
		if err != nil {
			return fmt.Errorf("marshaling request: %w", err)
		}
		reqBody = bytes.NewReader(data)
	}

	url := c.baseURL + path
	req, err := http.NewRequest(method, url, reqBody)
	if err != nil {
		return fmt.Errorf("creating request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	if requireAuth && c.token != "" {
		req.Header.Set("Authorization", "Bearer "+c.token)
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("executing request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusNoContent {
		return &noContentError{}
	}

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return fmt.Errorf("reading response: %w", err)
	}

	if resp.StatusCode >= 400 {
		var errResp ErrorResponse
		if json.Unmarshal(respBody, &errResp) == nil && errResp.Error != "" {
			return fmt.Errorf("api error (%d): %s", resp.StatusCode, errResp.Error)
		}
		return fmt.Errorf("api error (%d): %s", resp.StatusCode, string(respBody))
	}

	if out != nil && len(respBody) > 0 {
		if err := json.Unmarshal(respBody, out); err != nil {
			return fmt.Errorf("unmarshaling response: %w", err)
		}
	}

	return nil
}
