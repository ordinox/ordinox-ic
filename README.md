# `ordinox_tss_canister`

## Functions

> ##
>
> ## <i>Signer</i>
>
> ### - register_signers func
>
> This is to register array of node(signer)s onto TSS canister.
>
> ### - reset_signers func
>
> This is to clear registered signers over TSS canister.
>
> ### - get_signers func
>
> This is to query registered signers over TSS canister.
>
> ### - public_key func
>
> This is to query public_key of caller.
>
> ### - signer_approve func
>
> This is to register signer's withdraw approval, if number of approvals for withdraw is equal or bigger than threshold, create tx will be generated.
>
> ##
>
> ##
>
> ## <i>Threshold</i>
>
> ### - set_threshold func
>
> This is to set threshold of withdraw request approvals from different signers.
>
> ### - get_threshold func
>
> This is to query set threshold over TSS canister.
>
> ##
