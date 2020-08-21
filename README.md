# DEB an Event Bus framework for Delphi
Delphi Event Bus (for short DEB) is a publish/subscribe Event Bus framework for the Delphi platform.  This repo was originally developed by Daniele Spinetti, and cloned from https://github.com/spinettaro/delphi-event-bus

This repo is maintained and actively updated by Wuping Xin, and only supports the latest Delphi compiler version, i.e., Delphi 10.4 Sydney.

DEB is designed to decouple different parts/layers of your application while still allowing them to communicate efficiently.
It was inspired by EventBus framework for the Android platform.

![Delphi Event Bus Architecture](../master/Docs/DelphiEventBusArchitecture.png "Delphi Event Bus Architecture")

## Features
* __Easy and clean:__ DelphiEventBus is super easy to learn and use because it respects KISS and "Convention over configuration" design principles. By using default TEventBus instance, you can start immediately to delivery and receive events 
* __Designed to decouple different parts/layers of your application__
* __Event Driven__
* __Attributes based API:__ Simply put the Subscribe attribute on your subscriber method you are able to receive a specific event
* __Support different delivery mode:__ Specifying the TThreadMode in Subscribe attribute, you can choose to delivery the event in the Main Thread or in a Background ones, regardless where an event was posted. The EventBus will manage Thread synchronization     
* __Unit Tested__
* __Thread Safe__

## Show me the code
1.Define events:

```delphi
TEvent = class(TObject)
// additional information here
end;
```

2.Prepare subscribers:

 * Declare your subscribing method:
```delphi
[Subscribe]
procedure OnEvent(AEvent: TAnyTypeOfEvent);
begin
  // manage the event 	
end;
```

 * Register your subscriber:
```delphi
GlobalEventBus.RegisterSubscriber(self);
```

3.Post events:
```delphi
GlobalEventBus.post(LEvent);
```

## Support
* DEB is a 100% ObjectPascal framework so it works on VCL and Firemonkey
* Delphi 10.4 (or latest Delphi compiler) only

## Original License
  Copyright 2016-2020 Daniele Spinetti
  
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
  
## License
  Copyright 2020 Wuping Xin
  
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

## Maintainer
  This repo is actively maintenained and updated by Wuping Xin (@wxinix), and only
  supports Delphi 10.4 or latest Delphi compiler.