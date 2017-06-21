# EntitasKit

[![Build Status](https://travis-ci.org/mzaks/EntitasKit.svg?branch=master)](https://travis-ci.org/mzaks/EntitasKit)
[![codecov](https://codecov.io/gh/mzaks/EntitasKit/branch/master/graph/badge.svg)](https://codecov.io/gh/mzaks/EntitasKit)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

EntitasKit is a member of Entitas family. Entitas is a framework, which helps developers follow [Entity Component System architecture](https://en.wikipedia.org/wiki/Entity–component–system) (or ECS for short). Even though ECS finds it roots in game development. Entitas proved to be helpfull for App development. 

It can be used as: 
- [service registry](https://en.wikipedia.org/wiki/Service_locator_pattern)
- strategy for [event driven programming](https://en.wikipedia.org/wiki/Event-driven_programming)
- highly flexible data model, based on generic [product type](https://en.wikipedia.org/wiki/Product_type)

Applications designed with ECS, are proved to be easy to unit test and simple to change.

## How does it work

Let's imagine we have an app which has a NetworkingService. This networking service is implemented as a class or struct a struct we really don't care 😉. We need to be able to use this networking service from multiple places in our app. This is a typical use case for service locator pattern.

### How can we make it work with EntitasKit?
First we need to import EntitasKit and create a context.
```
import EntitasKit

let appContext = Context()
```
Now we need to define a _component_ which will hold reference to our networking service:
```
struct NetworkingServiceComponent: UniqueComponent {
    let ref: NetworkingService
}
```

The component is defined as _unique component_, this means that a context can hold only one instance of such component. And as a matter of fact, we would like to have only one networking service present in our application.
Now lets setup our context.

```
func setupAppContext() {
    appContext.setUniqueComponent(NetworkingServiceComponent(ref: NetworkingService()))
}
```

In the setup function, we instatiate networking service component with an instance of networking service and put the component into our app context.

Now, if we want to call `sendMessage` method on our networking service, we can do it as following:

```
appContext.uniqueComponent(NetworkingServiceComponent.self)?.ref.sendMessage()
```

I mentioned before that EntitasKit makes it easy to test your app. This is due to the fact, that even though the networking service is unique in your app it can be easily replaced/mocked in your test. Just call this in your test setup method.

```
appContext.setUniqueComponent(NetworkingServiceComponent(ref: NetworkingServiceMock()))
```

And call `setupAppContext()` during tear down.

---

Let me show you another typical problem which can be solved with service registry and EntitasKit.

Imagine you have an app and there is an unfortunate feature requirement. You need to show a modal view controller on top of another modal view controller. And than, there needs to be a way, not only to discard the current modal view controller, but all modal view controllers.

For this use case we will create another _component_:

```
struct ModalViewControllerComponent: Component {
    weak var ref: UIViewController?
}
```

This time our _component_ is not unique and the field of the component is a _weak_ reference to `UIViewController`. The refernce should be weak because we don't want to retain a view controller in our context. It should be retained only through our view controller hierarchy.

In the `viewDidLoad` method of the modal view controller, we can register our view by adding follwoing line:

```
appContext.createEntity().set(ModalViewControllerComponent(ref: self))
```

As you can see, this time we create an entity and set modal view controller component on it, referencing `self`. Entity is a very generic product type, which can hold any instance which implements `Component` or `UniqueComponent` protocol. The only caveat is that it cannot hold multiple instances of the same type.

Let's assume, we have a situation where we showed multiple modal view controller and want to dismiss them all. How can we do it?

```
for entity in appContext.group(ModalViewControllerComponent.matcher) {
    entity.get(ModalViewControllerComponent.self)?.ref?.dismiss(animated: false, completion: nil)
    entity.destroy()
}
```

In the code above, we see that we can ask context for group of entites which have `ModalViewControllerComponent`. `Group` implements `Sequence` protocol, this is why we can iterate through entities in it. Acceess the modal view controller component and call `dismiss` methd on it's reference. We than destroy the entity, because we don't need to hold the reference to the modal view controller any more.

---

## Strategy for event driven programming

Comming soon ...

## Highly flexible data model

Comming soon ...

## Entitas family
- [C#](https://github.com/sschmid/Entitas-CSharp)
- [C++](https://github.com/JuDelCo/Entitas-Cpp)
- [Objective-C](https://github.com/wooga/entitas)
- [Java](https://github.com/Rubentxu/entitas-java)
- [Python](https://github.com/Aenyhm/entitas-python)
- [Scala](https://github.com/darkoverlordofdata/entitas-scala)
- [Go](https://github.com/wooga/go-entitas)
- [F#](https://github.com/darkoverlordofdata/entitas-fsharp)
- [TypeScript](https://github.com/darkoverlordofdata/entitas-ts)
- [Kotlin](https://github.com/darkoverlordofdata/entitas-kotlin)
- [Haskell](https://github.com/mhaemmerle/entitas-haskell)
- [Erlang](https://github.com/mhaemmerle/entitas_erl)
- [Clojure](https://github.com/mhaemmerle/entitas-clj)
