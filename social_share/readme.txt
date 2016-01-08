1. Use config.php to set
 - base_url (where the folder will sit on a server)
 - photo_directory (local folder for saved photos)
 - email_from_address (should have same top level)
 - email_from_name (from name)
 - email_reply_address (should have same top level)
 - email_reply_name (reply to name)
 - email_subject (Email subject)

2. Make photos directory writeable 
 - chmod 0775

3. Point application to api.php
 - inside SCW-FaceAging-config.xml

<social emailscript="http://www.emailtestscript.com/api.php"></social>