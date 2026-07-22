<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;

class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'name',
        'first_name',
        'last_name',
        'date_of_birth',
        'father_name',
        'mother_name',
        'email',
        'phone',
        'address',
        'country_name',
        'country_code',
        'country_flag',
        'government_document_name',
        'government_document_path',
        'password',
        'is_admin',
        'status',
        'balance',
        'referral_code',
        'referred_by_user_id',
        'referral_bonus_earned',
        'last_seen_at',
        'email_verified_at',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'date_of_birth' => 'date',
            'is_admin' => 'boolean',
            'balance' => 'decimal:2',
            'referral_bonus_earned' => 'decimal:2',
            'last_seen_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    public function firebaseDeviceTokens(): HasMany
    {
        return $this->hasMany(FirebaseDeviceToken::class);
    }

    public function beneficiaries(): HasMany
    {
        return $this->hasMany(Beneficiary::class);
    }

    public function appNotifications(): HasMany
    {
        return $this->hasMany(AppNotification::class);
    }

    public function deviceLoginLogs(): HasMany
    {
        return $this->hasMany(DeviceLoginLog::class);
    }

    public function referredBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'referred_by_user_id');
    }
}
