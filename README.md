# TNKData

[![Version](http://cocoapod-badges.herokuapp.com/v/TNKData/badge.png)](http://cocoadocs.org/docsets/TNKData)
[![Platform](http://cocoapod-badges.herokuapp.com/p/TNKData/badge.png)](http://cocoadocs.org/docsets/TNKData)

TNKData is a work in progress replacement for Core Data with a focus on control, performance and concurrency. It is an object graph with a SQLite database storage backend.

## Goals

### Easy and efficient concurrency

There should never be a need for multiple context/connections, even when using TNKData from multiple threads. Internally objects and connections should lock when needed. This allows queries and changes to be made in the background much easier. It also allows objects to be shared between threads, reducing memory usage.

### Direct control of underlying database

While Core Data goes out of it's way to be flexible with it's backing store, SQLite is almost always the store of choice. TNKData uses SQLite explicitly and exclusively. Because of this, developers can safely access the storage database directly when needed, circumventing the object store.

Additionally, while a primary key is provided by default, developers are free to use their own primary keys. The implications of this is objects can be indexed in memory by the keys that will actually be used to query the objects reducing the need to even touch the database.

### Open source transparency

No matter how much Apple improves Core Data, because it is not open source developers are left to guess from the outside how it works. Simply by being open source, TNKData can be transparent as to how it works internally, and what it's performance characteristics and best practices should be.

## Usage

To run the example project; clone the repo, and run `pod install` from the Example directory first.

## Requirements

TNKData uses FMDB internally to access SQLite.

## Installation

TNKData is available through [CocoaPods](http://cocoapods.org), to install
it simply add the following line to your Podfile:

    pod "TNKData"

## Author

David Beck, code@thinkultimate.com

## License

TNKData is available under the MIT license. See the LICENSE file for more info.

