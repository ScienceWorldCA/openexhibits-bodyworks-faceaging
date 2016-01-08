<?php

require "config.php";
require 'phpmailer/PHPMailerAutoload.php';

$fail = false;

if ( isset ( $GLOBALS["HTTP_RAW_POST_DATA"] ) && isset ( $_GET['name'] ) ) {
 
    //the image file name
    $photo_id = rand(10,10000000);
	$fileName = $photo_id . ".jpg";
 
    // get the binary stream
    $im = $GLOBALS["HTTP_RAW_POST_DATA"];
 
    //write it
    $fp = fopen($config['photo_directory'].'/'.$fileName, 'wb');
    fwrite($fp, $im);
    fclose($fp);
 
 	// Fields 
	$name = $_REQUEST['name'];
	$email = $_REQUEST['email'];
 	$addtolist = $_REQUEST['addtolist'];
	
 	email_photo($photo_id,$email, $name, $addtolist); 
 
}  else {
 
    $fail = "Failed to write file"; 
	echo $fail; 
}



function email_photo($photo_id,$to_address,$to_name, $addtolist = false){
	require "config.php";
	$mail = new PHPMailer;
	$mail->setFrom($config['email_from_address'], $config['email_from_name']);
	$mail->addAddress($to_address, $to_name); 
	$mail->addReplyTo($config['email_reply_address'], $config['email_reply_name']);
	// Add as an attachemt (Photo is already included in the html body)
	//$mail->addAttachment($config['photo_directory'].'/'.$photo_id.".jpg");
	$mail->isHTML(true);

	$html = "<table width=\"600\" border=\"0\" cellpadding=\"0\" cellspacing=\"0\" border=\"0\"><tr><td width=\"20\" bgcolor=\"#017cc9\">&nbsp;</td><td width=\"560\" bgcolor=\"#017cc9\"><img src=\"".$config['base_url']."files/logo.png\" width=\"291\" height=\"137\" alt=\"\"/></td><td width=\"20\" bgcolor=\"#017cc9\">&nbsp;</td></tr><tr><td>&nbsp;</td><td><p>&nbsp;</p><p style=\"font-family:Arial, 'Helvetica Neue', Helvetica, sans-serif; font-weight:bold; line-height:18px; font-size:18px; color:#0477c5;\">Thank you for using Science World's Face Aging Exhibit!</p><p style=\"font-family:Arial, 'Helvetica Neue', Helvetica, sans-serif; font-weight:normal; line-height:18px; color:#737373; font-size:12px;\">Share the result with your friends and family to find out what they think! Use the hashtag #scienceworld and join in on the conversation.</p><p style=\"font-family:Arial, 'Helvetica Neue', Helvetica, sans-serif; font-weight:normal; line-height:18px; color:#737373; font-size:12px;\">If you like what you see, sign up for <a style=\"color:#0477c5;\" href=\"http://scienceworld.campayn.com/contact_list_form/signup/9803\"><strong>Science World's e-newsletter</strong></a> to stay up to date with future programming, events and activities happening under the dome.</p><p style=\"text-align:center;\"><img src=\"".$config['base_url'].$config['photo_directory']."/".$photo_id.".jpg"."\" width=\"300\" /></p><p style=\"font-family:Arial, 'Helvetica Neue', Helvetica, sans-serif; font-weight:bold; font-size:18px; color:#0477c5;\">Did you know?</p><p style=\"font-family:Arial, 'Helvetica Neue', Helvetica, sans-serif; font-weight:normal; line-height:18px; color:#737373; font-size:12px;\">Science World is a charitable organization that engages British Columbians in science and inspires futurescience and technology leadership throughout our province.</p><p style=\"font-family:Arial, 'Helvetica Neue', Helvetica, sans-serif; font-weight:normal; line-height:18px; color:#737373; font-size:12px;\">Visitors like you help contribute to making our mission a reality. Thank you!</p><a href=\"\"><img src=\"".$config['base_url']."files/support.png\"></a></td><td>&nbsp;</td></tr><tr><td>&nbsp;</td><td><br /><p style=\"font-family:Arial, 'Helvetica Neue', Helvetica, sans-serif; line-height:20px; text-align:center;font-weight:normal; color:#737373; font-size:12px;\"> <a href=\"https://www.facebook.com/scienceworldca/\"><img src=\"".$config['base_url']."files/A_icn_facebook.png\" /></a> <a href=\"https://twitter.com/scienceworldca\"><img src=\"".$config['base_url']."files/A_icn_twitter.png\" /></a> <a href=\"https://www.pinterest.com/scienceworldca/\"><img src=\"".$config['base_url']."files/A_icn_pinterest.png\" /></a> <a href=\"https://www.youtube.com/user/ScienceWorldTV\"><img src=\"".$config['base_url']."files/A_icn_instagram.png\" /></a> <a href=\"https://www.instagram.com/scienceworldca\"><img src=\"".$config['base_url']."files/A_icn_youtube.png\" /></a> <br /><br />TELUS World of Science<br />1455 Quebec Street<br />Vancouver, BC V6A 3Z7<br />info@scienceworld.ca<br />604.443.7440<br /></p></td><td>&nbsp;</td></tr><tr><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td></tr></table>";

	$mail->Subject = $config['email_subject'];
	$mail->Body    = $html;

	if(!$mail->send()) {
		 $fail = 'Mailer Error: ' . $mail->ErrorInfo;
		 echo $fail; 
	} else {
		 echo 'Message has been sent';
	}

}

/* Test
	email_photo('photo','reighny@gmail.com','Michael Hunter');
*/

