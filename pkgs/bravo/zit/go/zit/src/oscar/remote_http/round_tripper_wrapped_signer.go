package remote_http

import (
	"crypto/rand"
	"net/http"

	"code.linenisgreat.com/zit/go/zit/src/alfa/errors"
	"code.linenisgreat.com/zit/go/zit/src/bravo/bech32"
	"code.linenisgreat.com/zit/go/zit/src/charlie/repo_signing"
)

const (
	headerChallengeNonce    = "X-Zit-Challenge-Nonce"
	headerChallengeResponse = "X-Zit-Challenge-Response"
	headerRepoPublicKey     = "X-Zit-Repo-Public_Key"
	headerSha256Sig         = "X-Zit-Sha256-Sig"
)

type RoundTripperBufioWrappedSigner struct {
	repo_signing.PublicKey
	roundTripperBufio
}

// TODO extract signing into an agnostic middleware
func (roundTripper *RoundTripperBufioWrappedSigner) RoundTrip(
	request *http.Request,
) (response *http.Response, err error) {
	nonceBytes := make([]byte, 32)

	if _, err = rand.Read(nonceBytes); err != nil {
		err = errors.Wrap(err)
		return
	}

	nonce := bech32.Value{
		HRP:  "zit-nonce-v1",
		Data: nonceBytes,
	}

	if !roundTripper.PublicKey.IsEmpty() {
		request.Header.Add(headerChallengeNonce, nonce.String())
	}

	if response, err = roundTripper.roundTripperBufio.RoundTrip(
		request,
	); err != nil {
		err = errors.Wrap(err)
		return
	}

	sigString := response.Header.Get(headerChallengeResponse)

	if !roundTripper.PublicKey.IsEmpty() {
		var sig bech32.Value

		if err = sig.Set(sigString); err != nil {
			err = errors.Wrap(err)
			return
		}

		if err = repo_signing.VerifySignature(
			roundTripper.PublicKey,
			nonceBytes,
			sig.Data,
		); err != nil {
			err = errors.Wrap(err)
			return
		}
	}

	return
}
