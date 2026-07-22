<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome to City Go Remit</title>
</head>
<body style="margin:0;background:#f6f8fb;font-family:Arial,Helvetica,sans-serif;color:#172033;">
    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:#f6f8fb;padding:28px 14px;">
        <tr>
            <td align="center">
                <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width:580px;background:#ffffff;border:1px solid #dfe5ec;border-radius:22px;overflow:hidden;">
                    <tr>
                        <td style="padding:28px;border-bottom:1px solid #edf1f5;">
                            <div style="display:inline-block;padding:10px 14px;border:1px solid #d7e2df;border-radius:14px;background:#f4faf8;color:#00503a;font-size:14px;font-weight:700;">
                                City Go Remit
                            </div>
                            <h1 style="margin:22px 0 10px;font-size:28px;line-height:1.22;color:#111c2d;">Welcome, {{ $user->name }}</h1>
                            <p style="margin:0;font-size:15px;line-height:1.75;color:#4c5b68;">
                                Your account has been created successfully and your email is verified. You can now sign in to the City Go Remit app.
                            </p>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding:28px;">
                            <table role="presentation" width="100%" cellspacing="0" cellpadding="0">
                                <tr>
                                    <td style="padding:16px;border:1px solid #dfe7ef;border-radius:16px;background:#f8fafc;">
                                        <p style="margin:0 0 6px;font-size:12px;font-weight:700;letter-spacing:1px;text-transform:uppercase;color:#60707d;">Account Email</p>
                                        <p style="margin:0;font-size:16px;font-weight:700;color:#111c2d;">{{ $user->email }}</p>
                                    </td>
                                </tr>
                                <tr>
                                    <td height="12"></td>
                                </tr>
                                <tr>
                                    <td style="padding:16px;border:1px solid #dfe7ef;border-radius:16px;background:#ffffff;">
                                        <p style="margin:0 0 6px;font-size:12px;font-weight:700;letter-spacing:1px;text-transform:uppercase;color:#60707d;">Status</p>
                                        <p style="margin:0;font-size:16px;font-weight:700;color:#00503a;">Active & Verified</p>
                                    </td>
                                </tr>
                            </table>
                            <div style="margin-top:22px;padding:16px;border:1px solid #d7e2df;border-radius:16px;background:#f4faf8;color:#24584b;font-size:14px;line-height:1.7;">
                                Keep your login information private. City Go Remit will never ask for your password or OTP by phone or message.
                            </div>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding:18px 28px;background:#fbfcfe;border-top:1px solid #edf1f5;color:#71808d;font-size:12px;line-height:1.6;text-align:center;">
                            Thank you for joining City Go Remit.
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
