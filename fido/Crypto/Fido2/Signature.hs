module Crypto.Fido2.Signature (verifyX509Sig) where

import Crypto.Fido2.Attestation.Error (Error (InvalidSignature))
import Data.ByteString (ByteString)
import qualified Data.X509 as X509
import qualified Data.X509.Validation as X509

verifyX509Sig :: X509.SignatureALG -> X509.PubKey -> ByteString -> ByteString -> Either Error ()
verifyX509Sig sigType pub dat sig = case X509.verifySignature sigType pub dat sig of
  X509.SignaturePass -> pure ()
  X509.SignatureFailed _ -> Left InvalidSignature
