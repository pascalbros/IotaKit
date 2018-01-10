# IotaKit

The IOTA Swift API Library

It's a working-in-progress project, right now there is full support for address generation (with Keccak written in C) and basic commands to a full-node

## Compatibility

IotaKit should be compatible with all architectures, tested on iOS/MacOS

## Dependencies

`Foundation`

## Example

The usage should be straightforward, it is very similar to the [official JS lib](https://github.com/iotaledger/iota.lib.js)

```
let iota = Iota(node: "http://localhost", port: 14265)

iota.nodeInfo({ (result) in
	print(result)
}) { (error) in
	print(error)
}
```

## Author

IotaKit is maintained by [Pasquale Ambrosini](https://pascalbros.github.io)

You can follow me on Twitter at [@PascalAmbro](http://twitter.com/PascalAmbro) for project updates and releases.


## License
IotaKit is licensed under the terms of the MIT License. Please see the LICENSE file for full details.
