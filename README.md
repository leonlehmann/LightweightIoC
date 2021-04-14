# LightweightIoC
A simple and lightweight IoC container implementation.

### Example

```delphi
 // Register a type
 TIoC.Container.RegisterType<IDrivable, TCar>
 
 // Register a type with a unique name
 TIoC.Container.RegisterType<IDrivable, TBicycle>('bicycle')
 
 // Resolve a component
 TIoC.Container.Resolve<IDrivable>
 
 // Resolve a component registered with a unique name
 TIoC.Container.Resolve<IDrivable>('bicycle')
 
 // Register a singleton instance
 TIoC.Container.RegisterSingleton<IDrivable>(TCar.Create)
 
 // Register a singleton instance with a unique name
 TIoC.Container.RegisterSingleton<IDrivable>(TCar.Create, 'car')
```
