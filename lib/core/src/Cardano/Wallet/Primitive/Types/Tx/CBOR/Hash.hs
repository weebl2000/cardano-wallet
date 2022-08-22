
{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE QuantifiedConstraints #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}

module Cardano.Wallet.Primitive.Types.Tx.CBOR.Hash
    ( byronTxHash
    , alonzoTxHash
    , shelleyTxHash
    , fromShelleyTxId
    , parseTxHash
    )
    where

import Prelude

import Cardano.Api
    ( CardanoEra (..) )
import Cardano.Binary
    ( ToCBOR (..) )
import Cardano.Chain.UTxO
    ( ATxAux, taTx )
import Cardano.Crypto
    ( serializeCborHash )
import Cardano.Ledger.Core
    ( AuxiliaryData )
import Cardano.Ledger.Era
    ( Era (..) )
import Cardano.Ledger.Shelley.TxBody
    ( EraIndependentTxBody )
import Cardano.Wallet.Primitive.Types.Tx.CBOR
import Codec.CBOR.Read
    ( DeserialiseFailure )
import Data.Functor
    ( (<&>) )

import qualified Cardano.Crypto as CryptoC
import qualified Cardano.Crypto.Hash as Crypto
import qualified Cardano.Ledger.Alonzo.Tx as Alonzo
import qualified Cardano.Ledger.Babbage.Tx as Babbage hiding
    ( ScriptIntegrityHash, TxBody )
import qualified Cardano.Ledger.Core as SL.Core
import qualified Cardano.Ledger.Crypto as SL
import qualified Cardano.Ledger.SafeHash as SafeHash
import qualified Cardano.Ledger.Shelley.API as SL
import qualified Cardano.Ledger.ShelleyMA as MA
import qualified Cardano.Ledger.TxIn as TxIn
import qualified Cardano.Wallet.Primitive.Types.Hash as W

byronTxHash :: ATxAux a -> W.Hash tag
byronTxHash = W.Hash . CryptoC.hashToBytes . serializeCborHash . taTx

alonzoTxHash
    :: ( Crypto.HashAlgorithm (SL.HASH crypto)
       , SafeHash.HashAnnotated
             (SL.Core.TxBody era)
             EraIndependentTxBody
             crypto)
    => Babbage.ValidatedTx era
    -> W.Hash "Tx"
alonzoTxHash (Alonzo.ValidatedTx bod _ _ _) = fromShelleyTxId $ TxIn.txid bod

shelleyTxHash
    :: ( Era x
       , ToCBOR (AuxiliaryData x)
       , ToCBOR (SL.Core.TxBody x)
       , ToCBOR (SL.Core.Witnesses x))
    => MA.Tx x
    -> W.Hash "Tx"
shelleyTxHash
    (SL.Tx bod _ _) = fromShelleyTxId $ TxIn.txid bod

fromShelleyTxId :: SL.TxId crypto -> W.Hash "Tx"
fromShelleyTxId (SL.TxId h) =
    W.Hash $ Crypto.hashToBytes $ SafeHash.extractHash h

parseTxHash :: TxCBOR -> Either DeserialiseFailure (W.Hash "Tx")
parseTxHash cbor = parseCBOR cbor <&> \case
    EraTx ByronEra x -> byronTxHash x
    EraTx ShelleyEra x -> shelleyTxHash x
    EraTx MaryEra x -> shelleyTxHash x
    EraTx AllegraEra x -> shelleyTxHash x
    EraTx AlonzoEra x -> shelleyTxHash x
    EraTx BabbageEra x -> shelleyTxHash x
