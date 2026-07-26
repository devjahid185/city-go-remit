@php
    $accent = $accent ?? '#00503a';
    $badge = $badge ?? 'Security Verification';
    $details = $details ?? [];
    $footerNote = $footerNote ?? 'If you did not request this code, you can safely ignore this email.';
@endphp
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ $title }}</title>
</head>
<body style="margin:0;background:#f6f8fb;font-family:Arial,Helvetica,sans-serif;color:#172033;">
    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:#f6f8fb;padding:28px 14px;">
        <tr>
            <td align="center">
                <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width:560px;background:#ffffff;border:1px solid #dfe5ec;border-radius:20px;overflow:hidden;">
                    <tr>
                        <td style="padding:26px 28px 20px;border-bottom:1px solid #edf1f5;">
                            <div style="display:inline-block;padding:10px 14px;border:1px solid #d7e2df;border-radius:14px;background:#f4faf8;color:{{ $accent }};font-size:14px;font-weight:700;">
                                City Go Remit
                            </div>
                            <h1 style="margin:22px 0 8px;font-size:26px;line-height:1.25;color:#111c2d;">{{ $heading }}</h1>
                            <p style="margin:0;font-size:15px;line-height:1.7;color:#4c5b68;">{{ $intro }}</p>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding:28px;">
                            <p style="margin:0 0 12px;font-size:13px;font-weight:700;letter-spacing:1.5px;text-transform:uppercase;color:#60707d;">{{ $badge }}</p>
                            <div style="background:#f8fafc;border:1px solid #dfe7ef;border-radius:18px;padding:22px;text-align:center;">
                                <div style="font-size:38px;line-height:1;font-weight:800;letter-spacing:8px;color:{{ $accent }};">{{ $code }}</div>
                            </div>
                            @if(! empty($details))
                                <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="margin-top:20px;border:1px solid #e6edf3;border-radius:16px;overflow:hidden;">
                                    @foreach($details as $label => $value)
                                        <tr>
                                            <td style="padding:12px 14px;background:#fbfcfe;border-bottom:1px solid #edf2f7;color:#667585;font-size:13px;">{{ $label }}</td>
                                            <td align="right" style="padding:12px 14px;background:#ffffff;border-bottom:1px solid #edf2f7;color:#111c2d;font-size:13px;font-weight:700;">{{ $value }}</td>
                                        </tr>
                                    @endforeach
                                </table>
                            @endif
                            <p style="margin:18px 0 0;font-size:14px;line-height:1.7;color:#4c5b68;">
                                This code expires in <strong style="color:#111c2d;">{{ $expiresIn }}</strong>. Never share this OTP with anyone.
                            </p>
                            <div style="margin-top:22px;padding:14px 16px;border:1px solid #eadfc8;border-radius:14px;background:#fffaf0;color:#715218;font-size:13px;line-height:1.6;">
                                {{ $footerNote }}
                            </div>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding:18px 28px;background:#fbfcfe;border-top:1px solid #edf1f5;color:#71808d;font-size:12px;line-height:1.6;text-align:center;">
                            Sent by City Go Remit security system. Please do not reply to this automated email.
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
