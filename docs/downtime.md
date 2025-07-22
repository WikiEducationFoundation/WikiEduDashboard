If you need to take the Dashboard down but the server will still be running, it may be useful to put up a message to users to let them know what is going on.

Here's a template you can use for index.html:

```
<html>
  <p>Programs &amp; Events Dashboard has been having unexpected problems since 2021-03-16.</p>
  <p>I'm taking it offline to repair it. It will be back as soon as possible, likely later today.</p>
  <p>For details and updates, see <a href="https://phabricator.wikimedia.org/T277651">https://phabricator.wikimedia.org/T277651</a>.</p>
  <p>&nbsp;</p>
  <p>-Sage Ross (User:Ragesoss), Wiki Education</p>
  <p>sage@wikiedu.org</p>
</html>

```

To redirect all traffic to the index page, you can use this `.htaccess`:

```
RewriteEngine On
RewriteBase /
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.html [L]
```

You also must enable mod_rewrite (`sudo a2enmod rewrite`) and add a Directory stanza to an Apache site conf:
```
    <Directory "/var/www/html">
      AllowOverride All
    </Directory>
```
