package natsbackend

import (
	"context"

	"github.com/openbao/openbao/sdk/v2/framework"
	"github.com/openbao/openbao/sdk/v2/logical"

	"github.com/bonesofgiants/openbao-plugin-secrets-nats/pkg/stm"
)

// CredsStorage represents a Creds stored in the backend
type CredsStorage struct {
	Creds string `json:"creds"`
}

// CredsParameters represents the parameters for a Creds operation
type CredsParameters struct {
	Operator string `json:"operator,omitempty"`
	Account  string `json:"account,omitempty"`
	User     string `json:"user,omitempty"`
	Creds    string `json:"creds,omitempty"`
}

// CredsData represents the the data returned by a Creds operation
type CredsData struct {
	Creds string `json:"creds"`
}

func pathCreds(b *NatsBackend) []*framework.Path {
	paths := []*framework.Path{}
	paths = append(paths, pathUserCreds(b)...)
	return paths
}

func readCreds(ctx context.Context, storage logical.Storage, path string) (*CredsStorage, error) {
	return getFromStorage[CredsStorage](ctx, storage, path)
}

func deleteCreds(ctx context.Context, storage logical.Storage, path string) error {
	return deleteFromStorage(ctx, storage, path)
}

func createResponseCredsData(creds *CredsStorage) (*logical.Response, error) {
	d := &CredsData{
		Creds: creds.Creds,
	}

	rval := map[string]any{}
	err := stm.StructToMap(d, &rval)
	if err != nil {
		return nil, err
	}

	resp := &logical.Response{
		Data: rval,
	}
	return resp, nil
}

func addCreds(ctx context.Context, storage logical.Storage, path string, params CredsParameters) error {
	creds, err := getFromStorage[CredsStorage](ctx, storage, path)
	if err != nil {
		return err
	}

	if creds == nil {
		creds = &CredsStorage{}
	}

	creds.Creds = params.Creds

	// store the creds
	err = storeInStorage(ctx, storage, path, creds)
	if err != nil {
		return err
	}

	return nil
}

func listCreds(ctx context.Context, storage logical.Storage, path string) ([]string, error) {
	return storage.List(ctx, path)
}
