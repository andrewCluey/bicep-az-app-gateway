# bicep-az-app-gateway
Deploy an Azure Application Gateway


## Publishing an APIM API Backend.

### Back-end server pool
- This server pool is the internal virtual IP address of API Management.
- Every pool has settings like port, protocol, and cookie-based affinity. These settings are applied to all servers within the pool.

### Front-end port
- This public port is opened on the application gateway. Traffic that hits it gets redirected to one of the back-end servers.

### Listener 
- The listener has a front-end port, a protocol (Http or Https, these values are case sensitive), and the TLS/SSL certificate name (if configuring TLS offload).

### Rule 
- The rule binds a listener to a back-end server pool.

### Custom health probe
- Application Gateway, by default, uses IP address-based probes to figure out which servers in BackendAddressPool are active. API Management only responds to requests with the correct host header, so the default probes fail. You define a custom health probe to help the application gateway determine that the service is alive and should forward requests.

### Custom domain certificates
- To access API Management from the internet, create DNS records to map its host names to the Application Gateway front-end IP address. This mapping ensures that the Host header and certificate sent to API Management are valid. In this example, we use three certificates. They're for API Management's gateway (the back end), the developer portal, and the management endpoint.


## Expose the developer portal and management endpoint externally through Application Gateway
To also expose the developer portal and the management endpoint to external audiences through the application gateway, extra steps are needed to create a listener, probe, settings, and rules for each endpoint.


## To prevent Application Gateway WAF from breaking the download of OpenAPI specifications in the developer portal, disable the firewall rule 942200 - "Detects MySQL comment-/space-obfuscated injections and backtick termination".
```
Application Gateway WAF rules that might break the portal's functionality include:

920300, 920330, 931130, 942100, 942110, 942180, 942200, 942260, 942340, 942370 for the administrative mode
942200, 942260, 942370, 942430, 942440 for the published portal
```
