<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\View\View;

class AdminProfileController extends Controller
{
    public function __invoke(Request $request): View
    {
        return view('admin.profile.show', [
            'admin' => $request->user(),
        ]);
    }
}
