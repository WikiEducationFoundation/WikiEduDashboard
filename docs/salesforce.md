Wiki Education Dashboard links to Wiki Education's Salesforce instance to push and pull course data between the two. We use the Restforce gem to handle connecting to Salesforce and interacting with the API.

## Setup

(This documents the JWT Bearer Token method of Salesforce login. Username/password is also a valid way to do it.)

* Generate an x509 certificate for Salesforce to use for JWT Bearer Token flow.
  * Install the `fauthentic` gem
  * Generate a private key and cert with relevant options. eg,
  
```ruby
opts = {
  common_name: "dashboard.wikiedu.org",
  country: "US",
  state: "Washington",
  org: "WikiEducation",
  org_unit: "dashboard",
  email: "sage@wikiedu.org",
  expire_in_days: 3650,
  serial: 1
}
ssl = Fauthentic.generate(opts)
key_string = ssl.key.to_s
File.write 'x509.privkey', key_string
cert_string = ssl.cert.to_pem
File.write 'x509.pem', cert_string
```

* Create a new Connected App
  * Setup > App Manager > New Connected App
  * Check "Enable OAuth Settings"
  * Check "Use digital signatures"
  * Upload the x509 cert
  * Add "Full access" and "Perform requests on your behalf at any time" for Selected OAuth Scopes
  * Save

* Authorize the app for your Salesforce user account
  * Setup > App Manager > 'Manage' from the right-column dropdown for the app
  * Set "Admin approved users are pre-authorized" for Permitted Users, and save
  * Users > Profiles > select your user's profile > Assigned Connected Apps > add the app, save

* Get the `client_id` (Consumer Key) and `client_token` (Consumer Secret)
  * Setup > App Manager > 'View' from the right-column dropdown for the app
  
* Use the `client_id`, `client_token`, `instance_url` (the base URL of the Salesforce instance), `username`, and `jwt_key` (the private key for the x509 cert) to initialize the Restforce client.
