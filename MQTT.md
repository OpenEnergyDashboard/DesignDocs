# mqtt-evaluation

## potential-packages

### [Akiro MQTT](https://www.akiroio.com/)

1. What is its main features of interest
    1. Can it do MQTT protocol? Yes - MQTT Java client
    2. What are the main features beyond that? Can create a client instance and customize parameters 

2. Can it be used directly in OED
    * Not ideal because its a Java based interface
    * small company - not sure it will be frequently maintained and supported
    - Compatible license
3. What is its software license (even if not open source)
    -  Apache License 2.0 


### [Ably MQTT Broker](https://ably.com/)

1. What is its main features of interest
    1. Can it do MQTT protocol? Not an MQTT client - adapter. Recommended to use Ably when using devices that do not support Ably client libraries for MQTT protocol
    2. What are the main features beyond that? Converts MQTT data stream to Ably client library format

2. Can it be used directly in OED
    - No need for adapter to Ably

3. What is its software license (even if not open source)
    - Commercial organization - could not find license

### [Apache ActiveMQ](https://activemq.apache.org/index.html)

1. What is its main features of interest
    1. Can it do MQTT protocol? Yes - MQTT v3.1
    2. What are the main features beyond that? Supports variety of cross language clients and protocols from Java, C, C++, C#, Ruby, Perl, Python, PHP
    JMS 1.1 with full client implementation including JNDI
    High availability using shared storage
    Familiar JMS-based addressing model
    "Network of brokers" for distributing load
    KahaDB & JDBC options for persistence

2. Can it be used directly in OED
    - Yes - if possible to integrate java messaging service (JMS 1.1) into data pipeline
    - Well documented and well supported
    - Pro: maintained by apache open source

3. What is its software license (even if not open source)
    - Apache License 2.0

### [Apache ActiveMQ Artemis](https://activemq.apache.org/components/artemis/)

1. What is its main features of interest
    1. Can it do MQTT protocol? Yes - translates MQTT internally into OpenWire
    2. What are the main features beyond that?
    JMS 1.1 & 2.0 + Jakarta Messaging 2.0 & 3.0 with full client implementations including JNDI
High availability using shared storage or network replication
Simple & powerful protocol agnostic addressing model
Flexible clustering for distributing load
Advanced journal implementations for low-latency persistence as well as JDBC
High feature parity with ActiveMQ "Classic" to ease migration
Asynchronous mirroring for disaster recovery
Data Driven Load Balance

2. Can it be used directly in OED
    - Yes - if possible to integrate ActiveMQ Classic

3. What is its software license (even if not open source)
    - Apache License 2.0

### [Bevywise MQTT Broker](https://www.bevywise.com/mqtt-broker/)

1. What is its main features of interest
    1. Can it do MQTT protocol? Yes
    2. What are the main features beyond that? Provides versatile MQTT dashboard for managing IoT devices. Compatible with all standard MQTT clients 

2. Can it be used directly in OED
    - Yes, but not open source and not an MQTT client
    - Small company founded in India with location in Delaware, but seems well maintained and supported

3. What is its software license (even if not open source)
    - Commercial company, [license](https://www.bevywise.com/eula.html) has many restrictions on use

### [Cassandana](https://github.com/mtsoleimani/cassandana/)

1. What is its main features of interest
    1. Can it do MQTT protocol? Yes, MQTT broker written entirely in Java
    2. What are the main features beyond that? MQTT compliant broker.
Supports QoS 0, QoS 1 and QoS 2
TLS (SSL) Encryption
PostgreSQL, MySQL and MongoDB Authentication and Authorization
Supports Cassandra for Authentication, Authorization and Message Archiving
Supports HTTP REST API for Authentication and Authorization
Supports Redis for Authentication
Supports In-memory caching mechanism to reduce I/O operations
MQTT message archiver (Silo ported to Cassandana)
Easy configurable (YAML based)
Supports WebSocket

2. Can it be used directly in OED
    - Yes, but hasn't been updated since 2019

3. What is its software license (even if not open source)
    - Apache License 2.0


### [ejabberd](https://www.process-one.net/en/ejabberd/)

1. What is its main features of interest
    1. Can it do MQTT protocol? Yes, MQTT broker
    2. What are the main features beyond that? Multi-protocol support:
XMPP server, MQTT broker and SIP service
Backend integration with REST API and ejabberdctl command-line tool
Mobile libraries for iOS: XMPPFramework
Mobile libraries for Android: Smack, Retrofit
Web library with WebSocket support and fallback to BOSH support: Strophe
Open Source software: GitHub
Runs in a cluster out of the box
All nodes are active: platform built on top of ejabberd XMPP server supports fault tolerance mechanisms
Upgradable while it is running: unmatched uptime
No message lost: for each message, the XMPP server checks the status of delivery with an acknowledgment provided by the mobile app
Mobile network disconnections managed at XMPP server level

2. Can it be used directly in OED
    - Yes, open source package professionally maintained
    - Primarily written in Erlang

3. What is its software license (even if not open source)
    - ejabberd under GNU General Public License v2
    - ejabberd translations under MIT License

### [emitter](https://github.com/emitter-io/emitter)

1. What is its main features of interest
    1. Can it do MQTT protocol? Yes, clustered MQTT broker
    2. What are the main features beyond that?Publish/Subscribe using MQTT over TCP or Websockets.
Resilient, highly available and partition tolerant (AP in CAP terms).
Able to handle 3+ million of messages/sec on a single broker.
Supports message storage with history and message-level expiry.
Provides secure channel keys with permissions and can face the internet.
Automatic TLS/SSL and encrypted inter-broker communication.
Built-in monitoring with Prometheus, StatsD and more.
Shared subscriptions, links and private links for channels.
Easy deployment with Docker and Kubernetes of production-ready clusters.

2. Can it be used directly in OED
    - Yes, created to be used by real-time dashboard web applications
    - Written entirely in Go 
    - Well documented but not very well maintained

3. What is its software license (even if not open source)
    - GNU Affero General Public License v3.0

### [ascoltatori](https://github.com/moscajs/ascoltatori)

1. What is its main features of interest
    1. Can it do MQTT protocol? Yes, simple publish/subscribe library supporting all implementations of MQTT protocol
    2. What are the main features beyond that? 
    Also supports Redis, a key/value store created by @antirez.
MongoDB, a scalable, high-performance, document-oriented database.
Mosquitto and all implementations of the MQTT protocol.
RabbitMQ and all implementations of the AMQP protocol.
ZeroMQ to use Ascoltatori in a P2P fashion.
QlobberFSQ, a shared file system queue.
Apache Kafka, a high-throughput distributed messaging system.
Memory-only routing, using Qlobber.

2. Can it be used directly in OED
    - Yes, written entirely in JavaScript
    - Poorly maintained
    - Supports different brokers

3. What is its software license (even if not open source)
    - MIT License

### [Eclipse Paho HTML5 JavaScript over WebSocket](https://github.com/eclipse/paho.mqtt.javascript)

1. What is its main features of interest
    1. Can it do MQTT protocol? Yes, MQTT browser-based client library that uses WebSockets to connect to MQTT broker
    2. What are the main features beyond that? The Paho project has been created to provide reliable open-source implementations of open and standard messaging protocols aimed at new, existing, and emerging applications for Machine-to-Machine (M2M) and Internet of Things (IoT). Paho reflects the inherent physical and cost constraints of device connectivity. Its objectives include effective levels of decoupling between devices and applications, designed to keep markets open and encourage the rapid growth of scalable Web and Enterprise middleware and applications.

2. Can it be used directly in OED
    - Yes, written entirely in JS
    - Poorly maintained

3. What is its software license (even if not open source)
    - Eclipse Foundation License 

### [MQTT.js](https://github.com/mqttjs/MQTT.js)

1. What is its main features of interest
    1. Can it do MQTT protocol? Yes, client library for MQTT protocol written in JS for node.js and the browser
    2. What are the main features beyond that?

2. Can it be used directly in OED
    - Yes, will likely have to use this
    - very well documented and maintained
    - Written entirely in JavaScript

3. What is its software license (even if not open source)
    - MIT License

### [EMQX](https://www.emqx.com/en/products/emqx)

1. What is its main features of interest
    1. Can it do MQTT protocol? Yes, MQTT broker
    2. What are the main features beyond that? EMQX is a fully open source, highly scalable, highly available distributed MQTT messaging broker for IoT, M2M and Mobile applications that can handle tens of millions of concurrent clients.
Starting from 3.0 release, EMQX fully supports MQTT V5.0 protocol specifications and is backward compatible with MQTT V3.1 and V3.1.1, as well as other communication protocols such as MQTT-SN, CoAP, LwM2M, WebSocket and STOMP. The 3.0 release of the EMQX can scaled to 10+ million concurrent MQTT connections on one cluster

2. Can it be used directly in OED
    - Yes, self-managed MQTT messaging platform available 
    - Written almost entirely in Erlang
    - Can create a managed deployment of EMQX with EMQX Cloud for free
    - Very well maintained and documented, very popular


3. What is its software license (even if not open source)
    - Apache License 2.0

### [erl MQTT server](https://github.com/alekras/erl.mqtt.server)

1. What is its main features of interest
    1. Can it do MQTT protocol? Yes, server that implements MQTT protocol 
    2. What are the main features beyond that? The server consist of two OTP applications: core MQTT server and restful HTTP server for managing users DB. The both apps are combined in one release and are working closely.

2. Can it be used directly in OED
    - Yes, can use as MQTT server
    - Written entirely in Erlang 
    - not very well documented 

3. What is its software license (even if not open source)
    - unable to find license

### [Eurotech Edge Software](https://www.eurotech.com/edge-software/)

1. What is its main features of interest
    1. Can it do MQTT protocol? Yes, provides IoT Edge Framework to perform edge data processing, can connect to Artemis MQTT broker
    2. What are the main features beyond that?

2. Can it be used directly in OED
    - Not sure if this is what we're looking for

3. What is its software license (even if not open source)
    - Commercial company, commercial license

### [Flash MQ](https://www.flashmq.org/)

1. What is its main features of interest
    1. Can it do MQTT protocol? Yes, MQTT broker/server 
    2. What are the main features beyond that? MQTT 3.1, 3.1.1 and 5.0
Retained messages
Wills
Native HTTP1 websocket support, without external libraries. HTTP2 will not be implemented. There’s no advantage and it’s overly complex. You can always proxy with Nginx if you really want it.
SSL.
QoS 0, 1 and 2.
Authentication with plugin or ‘mosquitto_password_file’.
Native C++ FlashMQ authentication plugin interface.
Mosquitto auth plugin version 2 compatibility. This comes with a caveat though: it must be thread safe. Config options exist to perform some serialization, but it’s not a guarantee.
Intel SSE4.2 (SIMD) instructions for string/topic handling.
Persistent state (save sessions, subscriptions and retained messages).

2. Can it be used directly in OED
    - Yes, but written in C++
    - Decent documentation and maintaining

3. What is its software license (even if not open source)
    - GNU Affero General Public License v3.0

### [flespi](https://flespi.com/mqtt-broker)

1. What is its main features of interest
    1. Can it do MQTT protocol? Yes, MQTT broker
    2. What are the main features beyond that? Diagnostic-oriented MQTT client tool. Supports MQTT 5.0 and 3.1.X protocols, connections to multiple brokers, MQTT operations logs and multiple subscribe widgets with unique/history topic filtering mode. Saves configuration in browser's local cache.

2. Can it be used directly in OED
    - Yes, written in vue.js and JavaScript
    - Good support and maintenance
    - Operate broker via REST API 

3. What is its software license (even if not open source)
    - MIT License

### [aMQTT](https://github.com/Yakifo/amqtt)

1. What is its main features of interest
    1. Can it do MQTT protocol? Yes, MQTT v3.1.1 client and broker implementation
    2. What are the main features beyond that? Support QoS 0, QoS 1 and QoS 2 messages flow
Client auto-reconnection on network lost
Authentication through password file (more methods can be added through a plugin system)
Basic $SYS topics
TCP and websocket support
SSL support over TCP and websocket
Plugin system

2. Can it be used directly in OED
    - Yes, but written in Python
    - 

3. What is its software license (even if not open source)
    - MIT License

### []()

1. What is its main features of interest
    1. Can it do MQTT protocol? 
    2. What are the main features beyond that?

2. Can it be used directly in OED
    - ?

3. What is its software license (even if not open source)
    - ?



## Potential MQTT Simulators

### [http://www.steves-internet-guide.com/simple-controllable-mqtt-sensor/](http://www.steves-internet-guide.com/simple-controllable-mqtt-sensor/)
* would have to setup and install ourselves
* would be more customizable because of that

### [https://www.gambitcomm.com/site/mqttsimulator.php](https://www.gambitcomm.com/site/mqttsimulator.php) 

* costs $$$ to use 
* 