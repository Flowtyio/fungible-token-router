import "FungibleTokenRouter"

transaction(typeIdentifier: String) {
    prepare(acct: auth(BorrowValue) &Account) {
        let tokenType = CompositeType(typeIdentifier) ?? panic("invalid type identifier")

        let router = acct.storage.borrow<auth(FungibleTokenRouter.Owner) &FungibleTokenRouter.Router>(from: FungibleTokenRouter.StoragePath)
            ?? panic("router not found")
        router.removeOverride(type: tokenType)
    }
}