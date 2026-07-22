<?php

namespace Database\Seeders;

use App\Models\DriveOffer;
use App\Models\ExchangeRate;
use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        User::query()->updateOrCreate([
            'email' => env('ADMIN_EMAIL', 'admin@iqbal.local'),
        ], [
            'name' => env('ADMIN_NAME', 'City Go Remit Admin'),
            'phone' => '+880 1711-234567',
            'address' => 'Dhaka, Bangladesh',
            'password' => Hash::make(env('ADMIN_PASSWORD', 'Admin@12345')),
            'is_admin' => true,
            'status' => 'active',
            'last_seen_at' => now()->subMinutes(12),
            'email_verified_at' => now(),
        ]);

        $users = [
            ['Rahim Ud-Din', 'rahim@iqbal.local', '+880 1812-100001', 'Dhaka Division', 'active', now()->subMinutes(38)],
            ['Farhana Begum', 'farhana@iqbal.local', '+880 1812-100002', 'Chattogram Division', 'pending', now()->subHours(3)],
            ['Jamal Hossain', 'jamal@iqbal.local', '+880 1812-100003', 'Sylhet Division', 'active', now()->subDay()],
            ['Nusrat Jahan', 'nusrat@iqbal.local', '+880 1812-100004', 'Rajshahi Division', 'inactive', now()->subDays(4)],
            ['Arif Chowdhury', 'arif@iqbal.local', '+880 1812-100005', 'Khulna Division', 'active', now()->subHours(7)],
        ];

        foreach ($users as [$name, $email, $phone, $address, $status, $lastSeenAt]) {
            User::query()->updateOrCreate([
                'email' => $email,
            ], [
                'name' => $name,
                'phone' => $phone,
                'address' => $address,
                'password' => Hash::make('User@12345'),
                'is_admin' => false,
                'status' => $status,
                'last_seen_at' => $lastSeenAt,
                'email_verified_at' => $status === 'pending' ? null : now(),
            ]);
        }

        $offers = [
            ['Grameenphone', '3 GB Internet', 'internet', '3 GB', '3 Days', 98, '*121*3091#', true, 10, 'GP public internet package page'],
            ['Grameenphone', '7 GB Internet with Bonus', 'internet', '7 GB', '3 Days', 118, '*121*3188#', false, 20, 'GP public internet package page'],
            ['Grameenphone', '25 GB Internet with Bonus', 'internet', '25 GB', '7 Days', 219, null, true, 30, 'GP public internet package page'],
            ['Grameenphone', '20 GB Internet', 'internet', '20 GB', '30 Days', 499, null, false, 40, 'GP public internet package page'],
            ['Grameenphone', '60 GB Internet with Bonus', 'internet', '60 GB', '30 Days', 698, null, true, 50, 'GP public internet package page'],
            ['Grameenphone', '100 GB Internet', 'internet', '100 GB', '30 Days', 798, null, true, 60, 'GP public internet package page'],
            ['Robi', 'Easy Plan 1 GB', 'internet', '1 GB', '7 Days', 100, null, false, 70, 'Robi Easy Plan public page'],
            ['Robi', 'Entertainment Data Pack', 'internet', '10 GB', '7 Days', 199, '*123*0199#', true, 80, 'Robi public/news package reference'],
            ['Robi', 'Monthly Data Pack', 'internet', '60 GB', '30 Days', 698, null, true, 90, 'Public Robi offer reference'],
            ['Robi', 'Mega Data Pack', 'internet', '150 GB', '30 Days', 798, null, true, 100, 'Public Robi offer reference'],
            ['Airtel', 'Airtel Weekly Internet', 'internet', '10 GB', '7 Days', 199, null, true, 110, 'Admin-managed Airtel starter offer'],
            ['Airtel', 'Airtel Monthly Internet', 'internet', '60 GB', '30 Days', 698, null, true, 120, 'Admin-managed Airtel starter offer'],
            ['Airtel', 'Airtel Mega Internet', 'internet', '100 GB', '30 Days', 798, null, false, 130, 'Admin-managed Airtel starter offer'],
            ['Banglalink', '2 GB Internet', 'internet', '2 GB', '3 Days', 99, null, false, 140, 'Banglalink public internet page'],
            ['Banglalink', '25 GB Internet', 'internet', '25 GB', '7 Days', 229, '*121*129#', true, 150, 'Banglalink public internet page'],
            ['Banglalink', '40 GB Internet', 'internet', '40 GB', '7 Days', 249, null, true, 160, 'Banglalink public internet page'],
            ['Banglalink', '100 GB Internet', 'internet', '100 GB', '30 Days', 848, null, true, 170, 'Banglalink public internet page'],
            ['Banglalink', '150 GB Internet', 'internet', '150 GB', '30 Days', 999, null, false, 180, 'Banglalink public internet page'],
            ['Teletalk', '1 GB Internet', 'internet', '1 GB', '7 Days', 22, '*111*534#', false, 190, 'Teletalk public internet offers page'],
            ['Teletalk', '10 GB Internet', 'internet', '10 GB', '7 Days', 102, '*111*97#', true, 200, 'Teletalk public internet offers page'],
            ['Teletalk', '15 GB + Bonus Internet', 'internet', '15GB+768MB', '7 Days', 136, '*111*551#', true, 210, 'Teletalk public internet offers page'],
            ['Teletalk', '30 GB Internet', 'internet', '30 GB', '30 Days', 359, '*111*344#', true, 220, 'Teletalk public internet offers page'],
            ['Teletalk', '45 GB Internet', 'internet', '45 GB', '30 Days', 419, '*111*445#', false, 230, 'Teletalk public internet offers page'],
        ];

        foreach ($offers as [$operator, $title, $type, $data, $validity, $price, $code, $featured, $sort, $source]) {
            DriveOffer::query()->updateOrCreate([
                'operator' => $operator,
                'title' => $title,
                'validity' => $validity,
                'price' => $price,
            ], [
                'offer_type' => $type,
                'data_amount' => $data,
                'service_charge' => 0,
                'activation_code' => $code,
                'source_note' => $source,
                'description' => 'Admin-managed live catalog item. Please update price/availability from operator portal when needed.',
                'is_featured' => $featured,
                'is_active' => true,
                'sort_order' => $sort,
            ]);
        }

        $exchangeRates = [
            ['United States', 'US', '🇺🇸', 'USD', 'US Dollar', 118.5000, 0, 'Instant to 30 minutes', 10],
            ['United Kingdom', 'GB', '🇬🇧', 'GBP', 'British Pound', 156.2000, 0, 'Instant to 30 minutes', 20],
            ['European Union', 'EU', '🇪🇺', 'EUR', 'Euro', 136.4000, 0, 'Instant to 30 minutes', 30],
            ['Saudi Arabia', 'SA', '🇸🇦', 'SAR', 'Saudi Riyal', 31.6000, 0, 'Instant to 30 minutes', 40],
            ['United Arab Emirates', 'AE', '🇦🇪', 'AED', 'UAE Dirham', 32.2500, 0, 'Instant to 30 minutes', 50],
            ['Malaysia', 'MY', '🇲🇾', 'MYR', 'Malaysian Ringgit', 25.2000, 0, 'Instant to 30 minutes', 60],
            ['Singapore', 'SG', '🇸🇬', 'SGD', 'Singapore Dollar', 91.4000, 0, 'Instant to 30 minutes', 70],
            ['Canada', 'CA', '🇨🇦', 'CAD', 'Canadian Dollar', 86.1000, 0, 'Instant to 30 minutes', 80],
            ['Australia', 'AU', '🇦🇺', 'AUD', 'Australian Dollar', 78.2000, 0, 'Instant to 30 minutes', 90],
            ['India', 'IN', '🇮🇳', 'INR', 'Indian Rupee', 1.3800, 0, 'Instant to 30 minutes', 100],
        ];

        foreach ($exchangeRates as [$country, $countryCode, $flag, $currencyCode, $currencyName, $rate, $fee, $delivery, $sort]) {
            ExchangeRate::query()->updateOrCreate([
                'country_code' => $countryCode,
                'currency_code' => $currencyCode,
            ], [
                'country_name' => $country,
                'country_flag' => $flag,
                'currency_name' => $currencyName,
                'bdt_rate' => $rate,
                'service_fee' => $fee,
                'delivery_time' => $delivery,
                'note' => 'Admin-managed indicative exchange rate. Please update from your operational rate desk.',
                'is_active' => true,
                'sort_order' => $sort,
            ]);
        }
    }
}
