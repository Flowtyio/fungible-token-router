/*
FungibleTokenRouter forwards tokens from one account to another using
FungibleToken metadata views. If a token is not configured to be received,
any deposits will panic like they would a deposit that it attempt to a
non-existent receiver
*/

import "FungibleToken"
import "FungibleTokenMetadataViews"

access(all) contract FungibleTokenRouter {
    access(all) let StoragePath: StoragePath
    access(all) let PublicPath: PublicPath

    access(all) entitlement Owner

    access(all) resource Router: FungibleToken.Receiver {
        // a default address that is used for any token type that is not overridden
        access(all) var defaultAddress: Address

        // token type identifier -> destination address
        access(all) var addressOverrides: {String: Address}

        access(Owner) fun setDefaultAddress(_ addr: Address) {
            self.defaultAddress = addr
        }

        access(Owner) fun addOverride(type: Type, addr: Address) {
            self.addressOverrides[type.identifier] = addr
        }

        access(Owner) fun removeOverride(type: Type): Address? {
            return self.addressOverrides.remove(key: type.identifier)
        }

        access(all) fun deposit(from: @{FungibleToken.Vault}) {
            let destination = self.addressOverrides[from.getType().identifier] ?? self.defaultAddress

            if let md = from.resolveView(Type<FungibleTokenMetadataViews.FTVaultData>()) {
                let vaultData = md as! FungibleTokenMetadataViews.FTVaultData
                let receiver = getAccount(destination).capabilities.get<&{FungibleToken.Receiver}>(vaultData.receiverPath)
                
                assert(receiver.check(), message: "no receiver found at path: ".concat(vaultData.receiverPath.toString()))
                receiver.borrow()!.deposit(from: <-from)
            }

            panic("Could not find FungibleTokenMetadataViews.FTVaultData on depositing tokens")
        }

        access(all) view fun getSupportedVaultTypes(): {Type: Bool} {
            // theoretically any token is supported, it depends on the defaultAddress
            return {}
        }


        access(all) view fun isSupportedVaultType(type: Type): Bool {
            // theoretically any token is supported, it depends on the defaultAddress
            return true
        }

        init(defaultAddress: Address) {
            self.defaultAddress = defaultAddress
            self.addressOverrides = {}
        }
    }

    init() {
        let identifier = "FungibleTokenRouter_".concat(self.account.address.toString())
        self.StoragePath = StoragePath(identifier: identifier)!
        self.PublicPath = PublicPath(identifier: identifier)!
    }
}