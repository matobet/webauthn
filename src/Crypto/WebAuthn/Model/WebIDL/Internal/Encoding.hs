{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DefaultSignatures #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE TypeFamilies #-}

-- | Stability: internal
-- This module handles the encoding of structures passed to the
-- [create()](https://w3c.github.io/webappsec-credential-management/#dom-credentialscontainer-create)
-- and [get()](https://w3c.github.io/webappsec-credential-management/#dom-credentialscontainer-get)
-- methods while [Registering a New Credential](https://www.w3.org/TR/webauthn-2/#sctn-registering-a-new-credential)
-- and [Verifying an Authentication Assertion](https://www.w3.org/TR/webauthn-2/#sctn-verifying-assertion) respectively.
module Crypto.WebAuthn.Model.WebIDL.Internal.Encoding
  ( Encode (..),
  )
where

import qualified Crypto.WebAuthn.Cose.SignAlg as Cose
import qualified Crypto.WebAuthn.Encoding.Binary as B
import qualified Crypto.WebAuthn.Encoding.Strings as S
import qualified Crypto.WebAuthn.Model.Kinds as K
import qualified Crypto.WebAuthn.Model.Types as M
import Crypto.WebAuthn.Model.WebIDL.Internal.Convert (Convert (IDL))
import qualified Crypto.WebAuthn.Model.WebIDL.Types as IDL
import qualified Crypto.WebAuthn.WebIDL as IDL
import Data.Coerce (Coercible, coerce)
import qualified Data.Map as Map
import Data.Singletons (SingI)

-- | @'Encode' hs@ indicates that the Haskell-specific type @hs@ can be
-- encoded to the more generic JavaScript type @'IDL' hs@ with the 'encode' function.
class Convert a => Encode a where
  encode :: a -> IDL a
  default encode :: Coercible a (IDL a) => a -> IDL a
  encode = coerce

instance (Functor f, Encode a) => Encode (f a) where
  encode = fmap encode

instance Encode M.RpId

instance Encode M.RelyingPartyName

instance Encode M.UserHandle

instance Encode M.UserAccountDisplayName

instance Encode M.UserAccountName

instance Encode M.Challenge

instance Encode M.Timeout

instance Encode M.CredentialId

instance Encode M.AuthenticationExtensionsClientInputs where
  -- TODO: Extensions are not implemented by this library, see the TODO in the
  -- module documentation of `Crypto.WebAuthn.Model` for more information.
  encode M.AuthenticationExtensionsClientInputs {} = Map.empty

-- | <https://www.iana.org/assignments/cose/cose.xhtml#algorithms>
instance Encode Cose.CoseSignAlg where
  encode = Cose.fromCoseSignAlg

-- | <https://www.w3.org/TR/webauthn-2/#enum-credentialType>
instance Encode M.CredentialType where
  encode = S.encodeCredentialType

-- | <https://www.w3.org/TR/webauthn-2/#enumdef-authenticatortransport>
instance Encode M.AuthenticatorTransport where
  encode = S.encodeAuthenticatorTransport

-- | <https://www.w3.org/TR/webauthn-2/#enumdef-authenticatorattachment>
instance Encode M.AuthenticatorAttachment where
  encode = S.encodeAuthenticatorAttachment

-- | <https://www.w3.org/TR/webauthn-2/#enum-residentKeyRequirement>
instance Encode M.ResidentKeyRequirement where
  encode = S.encodeResidentKeyRequirement

-- | <https://www.w3.org/TR/webauthn-2/#enum-userVerificationRequirement>
instance Encode M.UserVerificationRequirement where
  encode = S.encodeUserVerificationRequirement

-- | <https://www.w3.org/TR/webauthn-2/#enum-attestation-convey>
instance Encode M.AttestationConveyancePreference where
  encode = S.encodeAttestationConveyancePreference

instance Encode M.CredentialRpEntity where
  encode M.CredentialRpEntity {..} =
    IDL.PublicKeyCredentialRpEntity
      { id = encode creId,
        name = encode creName
      }

instance Encode M.CredentialUserEntity where
  encode M.CredentialUserEntity {..} =
    IDL.PublicKeyCredentialUserEntity
      { id = encode cueId,
        displayName = encode cueDisplayName,
        name = encode cueName
      }

instance Encode M.CredentialParameters where
  encode M.CredentialParameters {..} =
    IDL.PublicKeyCredentialParameters
      { littype = encode cpTyp,
        alg = encode cpAlg
      }

instance Encode M.CredentialDescriptor where
  encode M.CredentialDescriptor {..} =
    IDL.PublicKeyCredentialDescriptor
      { littype = encode cdTyp,
        id = encode cdId,
        transports = encode cdTransports
      }

instance Encode M.AuthenticatorSelectionCriteria where
  encode M.AuthenticatorSelectionCriteria {..} =
    IDL.AuthenticatorSelectionCriteria
      { authenticatorAttachment = encode ascAuthenticatorAttachment,
        residentKey = Just $ encode ascResidentKey,
        -- [(spec)](https://www.w3.org/TR/webauthn-2/#dom-authenticatorselectioncriteria-requireresidentkey)
        -- Relying Parties SHOULD set it to true if, and only if, residentKey is set to required.
        requireResidentKey = Just (ascResidentKey == M.ResidentKeyRequirementRequired),
        userVerification = Just $ encode ascUserVerification
      }

instance Encode (M.CredentialOptions 'K.Registration) where
  encode M.CredentialOptionsRegistration {..} =
    IDL.PublicKeyCredentialCreationOptions
      { rp = encode corRp,
        user = encode corUser,
        challenge = encode corChallenge,
        pubKeyCredParams = encode corPubKeyCredParams,
        timeout = encode corTimeout,
        excludeCredentials = Just $ encode corExcludeCredentials,
        authenticatorSelection = encode corAuthenticatorSelection,
        attestation = Just $ encode corAttestation,
        extensions = encode corExtensions
      }

instance Encode (M.CredentialOptions 'K.Authentication) where
  encode M.CredentialOptionsAuthentication {..} =
    IDL.PublicKeyCredentialRequestOptions
      { challenge = encode coaChallenge,
        timeout = encode coaTimeout,
        rpId = encode coaRpId,
        allowCredentials = Just $ encode coaAllowCredentials,
        userVerification = Just $ encode coaUserVerification,
        extensions = encode coaExtensions
      }

-- | [(spec)](https://www.w3.org/TR/webauthn-2/#iface-pkcredential)
-- Encodes the PublicKeyCredential for attestation, this instance is mostly used in the tests where we emulate the
-- of the client.
instance Encode (M.Credential 'K.Registration 'True) where
  encode M.Credential {..} =
    IDL.PublicKeyCredential
      { rawId = encode cIdentifier,
        response = encode cResponse,
        -- TODO: Extensions are not implemented by this library, see the TODO in the
        -- module documentation of `Crypto.WebAuthn.Model` for more information.
        clientExtensionResults = Map.empty
      }

-- | [(spec)](https://www.w3.org/TR/webauthn-2/#dom-authenticatorresponse-clientdatajson)
instance SingI c => Encode (M.CollectedClientData (c :: K.CeremonyKind) 'True) where
  encode ccd = IDL.URLEncodedBase64 $ M.unRaw $ M.ccdRawData ccd

instance Encode (M.AuthenticatorResponse 'K.Authentication 'True) where
  encode M.AuthenticatorResponseAuthentication {..} =
    IDL.AuthenticatorAssertionResponse
      { clientDataJSON = encode araClientData,
        authenticatorData = IDL.URLEncodedBase64 $ M.unRaw $ M.adRawData araAuthenticatorData,
        signature = IDL.URLEncodedBase64 $ M.unAssertionSignature araSignature,
        userHandle = IDL.URLEncodedBase64 . M.unUserHandle <$> araUserHandle
      }

instance Encode (M.Credential 'K.Authentication 'True) where
  encode M.Credential {..} =
    IDL.PublicKeyCredential
      { rawId = encode cIdentifier,
        response = encode cResponse,
        -- TODO: Extensions are not implemented by this library, see the TODO in the
        -- module documentation of `Crypto.WebAuthn.Model` for more information.
        clientExtensionResults = Map.empty
      }

-- | [(spec)](https://www.w3.org/TR/webauthn-2/#iface-authenticatorresponse)
instance Encode (M.AuthenticatorResponse 'K.Registration 'True) where
  encode M.AuthenticatorResponseRegistration {..} =
    IDL.AuthenticatorAttestationResponse
      { clientDataJSON = encode arrClientData,
        attestationObject = encode arrAttestationObject,
        transports = Just $ encode arrTransports
      }

-- | [(spec)](https://www.w3.org/TR/webauthn-2/#dom-authenticatorattestationresponse-attestationobject)
instance Encode (M.AttestationObject 'True) where
  encode ao = IDL.URLEncodedBase64 $ B.encodeAttestationObject ao
