import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  Activity,
  ArrowRight,
  BarChart3,
  Bell,
  CheckCircle2,
  Edit3,
  Gift,
  Image as ImageIcon,
  Landmark,
  LayoutDashboard,
  LogOut,
  MessageCircle,
  Menu,
  Plus,
  ReceiptText,
  Search,
  Send,
  Settings,
  ShieldCheck,
  Smartphone,
  Trash2,
  UserRound,
  UsersRound,
  Wallet,
  Wifi,
  X,
  Youtube,
} from 'lucide-react';
import api from './api/client.js';

const navItems = [
  { key: 'dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { key: 'banners', label: 'App Banners', icon: ImageIcon },
  { key: 'general-settings', label: 'General Settings', icon: Settings },
  { key: 'notifications', label: 'Push Notifications', icon: Bell },
  { key: 'referrals', label: 'Referral System', icon: Gift },
  { key: 'users', label: 'User Management', icon: UsersRound },
  { key: 'recharges', label: 'Recharge Transactions', icon: Smartphone },
  { key: 'bills', label: 'Bill Payments', icon: ReceiptText },
  { key: 'bank-transfers', label: 'Bank Transfers', icon: Landmark },
  { key: 'wallet-withdrawals', label: 'Wallet Withdrawals', icon: Wallet },
  { key: 'exchange-rates', label: 'Exchange Rates', icon: BarChart3 },
  { key: 'drive-offers', label: 'Drive Offers', icon: Wifi },
  { key: 'drive-orders', label: 'Offer Orders', icon: Activity },
  { key: 'chats', label: 'Live Chat', icon: MessageCircle },
  { key: 'profile', label: 'Admin Profile', icon: UserRound },
];

const emptyForm = {
  name: '',
  first_name: '',
  last_name: '',
  email: '',
  phone: '',
  address: '',
  country_name: '',
  country_code: '',
  balance: '0',
  status: 'active',
  is_admin: false,
  chat_banned: false,
  ban_reason: '',
  password: '',
  password_confirmation: '',
};

export function App() {
  const [admin, setAdmin] = useState(() => readStoredAdmin());
  const [token, setToken] = useState(() => localStorage.getItem('admin_token'));

  useEffect(() => {
    const handleExpired = () => {
      setToken(null);
      setAdmin(null);
    };

    window.addEventListener('admin-auth-expired', handleExpired);
    return () => window.removeEventListener('admin-auth-expired', handleExpired);
  }, []);

  if (!token || !admin) {
    return <LoginPage onLogin={(nextAdmin, nextToken) => {
      localStorage.setItem('admin_token', nextToken);
      localStorage.setItem('admin_user', JSON.stringify(nextAdmin));
      setToken(nextToken);
      setAdmin(nextAdmin);
    }} />;
  }

  return <AdminShell admin={admin} onAdminChange={(nextAdmin) => {
    localStorage.setItem('admin_user', JSON.stringify(nextAdmin));
    setAdmin(nextAdmin);
  }} onLogout={() => {
    localStorage.removeItem('admin_token');
    localStorage.removeItem('admin_user');
    setToken(null);
    setAdmin(null);
  }} />;
}

function readStoredAdmin() {
  const stored = localStorage.getItem('admin_user');
  if (!stored) return null;

  try {
    const parsed = JSON.parse(stored);
    if (!parsed || typeof parsed !== 'object' || !parsed.email) {
      localStorage.removeItem('admin_user');
      localStorage.removeItem('admin_token');
      return null;
    }
    return parsed;
  } catch (_) {
    localStorage.removeItem('admin_user');
    localStorage.removeItem('admin_token');
    return null;
  }
}

function LoginPage({ onLogin }) {
  const [form, setForm] = useState({ email: '', password: '' });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  async function submit(event) {
    event.preventDefault();
    setLoading(true);
    setError('');

    try {
      const { data } = await api.post('/admin/login', form);
      onLogin(data.admin, data.token);
    } catch (apiError) {
      setError(apiError.response?.data?.message || 'Login failed. Please check your admin credentials.');
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="min-h-screen bg-[#f6f7f9] px-4 py-8 text-slate-950">
      <div className="mx-auto grid min-h-[calc(100vh-4rem)] max-w-6xl items-center gap-8 lg:grid-cols-[1fr_440px]">
        <section className="hidden rounded-[14px] border border-slate-200 bg-white p-8 shadow-sm lg:block">
          <div className="inline-flex items-center gap-2 rounded-full border border-red-100 bg-red-50 px-4 py-2 text-sm font-medium text-red-700">
            <ShieldCheck size={17} /> Secure Admin API Console
          </div>
          <h1 className="mt-8 max-w-xl text-5xl font-medium tracking-tight text-slate-950">
            Manage users, recharge activity and platform controls from one calm workspace.
          </h1>
          <p className="mt-5 max-w-lg text-base leading-7 text-slate-600">
            React admin stays separate from Laravel. Laravel works as a clean API backend with protected bearer-token access.
          </p>
          <div className="mt-10 grid grid-cols-3 gap-4">
            {['API First', 'Protected', 'Responsive'].map((item) => (
              <div key={item} className="rounded-xl border border-slate-200 bg-slate-50 p-4">
                <CheckCircle2 className="text-red-600" size={20} />
                <p className="mt-3 text-sm font-medium text-slate-800">{item}</p>
              </div>
            ))}
          </div>
        </section>

        <form onSubmit={submit} className="rounded-[14px] border border-slate-200 bg-white p-6 shadow-sm sm:p-8">
          <img src="/logo.png" alt="City Go Remit logo" className="h-12 w-12 rounded-xl object-cover shadow-sm" />
          <h2 className="mt-7 text-2xl font-medium text-slate-950">Admin Login</h2>
          <p className="mt-2 text-sm text-slate-500">Sign in with your authorized admin account.</p>

          {error ? <div className="mt-5 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">{error}</div> : null}

          <div className="mt-6 space-y-4">
            <Field label="Email address" type="email" value={form.email} onChange={(email) => setForm({ ...form, email })} required />
            <Field label="Password" type="password" value={form.password} onChange={(password) => setForm({ ...form, password })} required />
          </div>

          <button disabled={loading} className="mt-6 flex w-full items-center justify-center gap-2 rounded-xl bg-red-600 px-5 py-3 text-sm font-medium text-white transition hover:bg-red-700 disabled:opacity-60">
            {loading ? 'Signing in...' : 'Access Admin Panel'}
            <ArrowRight size={17} />
          </button>
        </form>
      </div>
    </main>
  );
}

function AdminShell({ admin, onAdminChange, onLogout }) {
  const [activePage, setActivePage] = useState('dashboard');
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [logoutOpen, setLogoutOpen] = useState(false);
  const [loggingOut, setLoggingOut] = useState(false);
  const openChatFromNotification = useCallback(() => setActivePage('chats'), []);

  async function logout() {
    setLoggingOut(true);
    try {
      await api.post('/admin/logout');
    } finally {
      setLoggingOut(false);
      onLogout();
    }
  }

  return (
    <div className="min-h-screen bg-[#f6f7f9] text-slate-950">
      <aside className={`fixed inset-y-0 left-0 z-40 flex w-[min(22rem,calc(100vw-1rem))] flex-col border-r border-slate-200 bg-white/95 px-4 py-4 shadow-2xl shadow-slate-950/10 backdrop-blur transition duration-300 lg:w-[19rem] lg:translate-x-0 lg:bg-white lg:shadow-none ${sidebarOpen ? 'translate-x-0' : '-translate-x-full'}`}>
        <div className="flex items-center justify-between rounded-[14px] border border-slate-200 bg-slate-50 p-3">
          <div className="flex min-w-0 items-center gap-3">
            <img src="/logo.png" alt="City Go Remit logo" className="h-12 w-12 shrink-0 rounded-xl object-cover shadow-sm" />
            <div className="min-w-0">
              <p className="truncate text-sm font-medium text-slate-950">City Go Remit</p>
              <p className="truncate text-xs text-slate-500">Secure Admin Console</p>
            </div>
          </div>
          <button className="rounded-xl border border-slate-200 bg-white p-2 text-slate-500 lg:hidden" onClick={() => setSidebarOpen(false)}><X size={20} /></button>
        </div>

        <div className="mt-5 rounded-[14px] border border-red-100 bg-red-50 px-4 py-3">
          <p className="text-xs uppercase tracking-[0.18em] text-red-600">Workspace</p>
          <p className="mt-1 text-sm font-medium text-slate-900">City Go Remit Operations</p>
        </div>

        <nav className="mt-5 flex-1 space-y-1 overflow-y-auto pr-1">
          {navItems.map((item) => {
            const Icon = item.icon;
            const active = activePage === item.key;
            return (
              <button key={item.key} onClick={() => { setActivePage(item.key); setSidebarOpen(false); }} className={`group flex w-full items-center gap-3 rounded-xl px-3.5 py-3.5 text-left text-sm transition ${active ? 'bg-red-600 text-white shadow-sm' : 'text-slate-600 hover:bg-slate-100 hover:text-slate-950'}`}>
                <span className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-xl transition ${active ? 'bg-white/15 text-white' : 'bg-slate-100 text-slate-500 group-hover:bg-white group-hover:text-red-600'}`}>
                  <Icon size={18} />
                </span>
                <span className="min-w-0 flex-1 truncate font-medium">{item.label}</span>
                {active ? <span className="h-2 w-2 rounded-full bg-white" /> : null}
              </button>
            );
          })}
        </nav>

        <div className="mt-5 rounded-[14px] border border-slate-200 bg-slate-50 p-4">
          <div className="flex items-center gap-3">
            <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-slate-900 text-sm font-medium text-white">{admin.name?.slice(0, 2).toUpperCase()}</div>
            <div className="min-w-0">
              <p className="truncate text-sm font-medium text-slate-900">{admin.name}</p>
              <p className="mt-1 truncate text-xs text-slate-500">{admin.email}</p>
            </div>
          </div>
          <button onClick={() => setLogoutOpen(true)} className="mt-4 flex min-h-11 w-full items-center justify-center gap-2 rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-100">
            <LogOut size={16} /> Logout
          </button>
        </div>
      </aside>

      {sidebarOpen ? <button aria-label="Close sidebar" className="fixed inset-0 z-30 bg-slate-950/45 backdrop-blur-sm lg:hidden" onClick={() => setSidebarOpen(false)} /> : null}

      <main className="lg:pl-[19rem]">
        <header className="sticky top-0 z-20 border-b border-slate-200 bg-white/90 px-4 py-3 backdrop-blur sm:px-6 sm:py-4">
          <div className="flex items-center gap-3">
            <button className="flex h-11 w-11 items-center justify-center rounded-xl border border-slate-200 bg-white text-slate-700 shadow-sm lg:hidden" onClick={() => setSidebarOpen(true)}><Menu size={20} /></button>
            <div className="min-w-0 flex-1">
              <p className="text-xs uppercase tracking-[0.24em] text-red-600">Admin Panel</p>
              <h1 className="mt-1 truncate text-lg font-medium text-slate-950 sm:text-xl">{navItems.find((item) => item.key === activePage)?.label}</h1>
            </div>
            <div className="hidden items-center gap-3 rounded-xl border border-slate-200 bg-slate-50 px-4 py-2 md:flex">
              <div className="h-2.5 w-2.5 rounded-full bg-emerald-500" />
              <span className="text-sm text-slate-600">API Connected</span>
            </div>
            <button onClick={() => setLogoutOpen(true)} className="hidden h-11 items-center gap-2 rounded-xl border border-slate-200 bg-white px-4 text-sm font-medium text-slate-700 shadow-sm hover:bg-slate-50 sm:flex">
              <LogOut size={16} /> Logout
            </button>
          </div>
        </header>

        <section className="p-3 sm:p-5 lg:p-6">
          {activePage === 'dashboard' ? <Dashboard onNavigate={setActivePage} /> : null}
          {activePage === 'banners' ? <BannersPage /> : null}
          {activePage === 'general-settings' ? <GeneralSettingsPage /> : null}
          {activePage === 'notifications' ? <NotificationsPage /> : null}
          {activePage === 'referrals' ? <ReferralAdminPage /> : null}
          {activePage === 'users' ? <UsersPage /> : null}
          {activePage === 'recharges' ? <RechargesPage /> : null}
          {activePage === 'bills' ? <BillPaymentsPage /> : null}
          {activePage === 'bank-transfers' ? <BankTransfersPage /> : null}
          {activePage === 'wallet-withdrawals' ? <WalletWithdrawalsPage /> : null}
          {activePage === 'exchange-rates' ? <ExchangeRatesPage /> : null}
          {activePage === 'drive-offers' ? <DriveOffersPage /> : null}
          {activePage === 'drive-orders' ? <DriveOfferOrdersPage /> : null}
          {activePage === 'chats' ? <ChatSupportPage /> : null}
          {activePage === 'profile' ? <ProfilePage admin={admin} onAdminChange={onAdminChange} /> : null}
        </section>
      </main>

      {logoutOpen ? (
        <LogoutDialog
          admin={admin}
          loading={loggingOut}
          onCancel={() => setLogoutOpen(false)}
          onConfirm={logout}
        />
      ) : null}
      {activePage !== 'chats' ? <ChatGlobalNotifier onOpenChat={openChatFromNotification} /> : null}
    </div>
  );
}

function LogoutDialog({ admin, loading, onCancel, onConfirm }) {
  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-slate-950/45 p-3 sm:items-center">
      <div className="w-full max-w-md rounded-[14px] border border-slate-200 bg-white p-5 shadow-sm">
        <div className="flex items-start gap-4">
          <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-red-50 text-red-600">
            <LogOut size={22} />
          </div>
          <div className="min-w-0 flex-1">
            <h3 className="text-xl font-medium text-slate-950">Sign out from admin?</h3>
            <p className="mt-2 text-sm leading-6 text-slate-500">
              You are signed in as <span className="font-medium text-slate-800">{admin.email}</span>. You will need to login again to manage the panel.
            </p>
          </div>
        </div>

        <div className="mt-5 rounded-xl border border-slate-200 bg-slate-50 p-4">
          <p className="text-sm font-medium text-slate-900">{admin.name}</p>
          <p className="mt-1 text-xs text-slate-500">Current admin session will be closed securely.</p>
        </div>

        <div className="mt-5 flex flex-col-reverse gap-3 sm:flex-row sm:justify-end">
          <button
            type="button"
            disabled={loading}
            onClick={onCancel}
            className="rounded-xl border border-slate-200 px-5 py-3 text-sm text-slate-600 hover:bg-slate-50 disabled:opacity-60"
          >
            Stay Logged In
          </button>
          <button
            type="button"
            disabled={loading}
            onClick={onConfirm}
            className="rounded-xl bg-red-600 px-5 py-3 text-sm font-medium text-white hover:bg-red-700 disabled:opacity-60"
          >
            {loading ? 'Signing out...' : 'Yes, Sign Out'}
          </button>
        </div>
      </div>
    </div>
  );
}

function ChatGlobalNotifier({ onOpenChat }) {
  const [messageAlerts, setMessageAlerts] = useState([]);
  const knownUserMessageIdsRef = useRef(new Set());
  const seededRef = useRef(false);

  useEffect(() => {
    if ('Notification' in window && Notification.permission === 'default') {
      Promise.resolve(Notification.requestPermission()).catch(() => {});
    }
  }, []);

  useEffect(() => {
    let mounted = true;

    async function loadLatestChats() {
      try {
        const response = await api.get('/admin/chats');
        if (!mounted) return;

        const conversations = response.data?.conversations?.data || [];
        const incomingAlerts = [];

        conversations.forEach((conversation) => {
          [...(conversation.messages || [])].reverse().forEach((message) => {
            if (!message || message.sender_type !== 'user') return;

            const messageId = Number(message.id || 0);
            if (!messageId || knownUserMessageIdsRef.current.has(messageId)) return;

            knownUserMessageIdsRef.current.add(messageId);
            if (seededRef.current) {
              incomingAlerts.push({ id: messageId, conversation, message });
            }
          });
        });

        seededRef.current = true;
        if (!incomingAlerts.length) return;

        playChatTone('receive');
        incomingAlerts.forEach((alert) => notifyBrowserForGlobalChat(alert, onOpenChat));
        setMessageAlerts((current) => [...current, ...incomingAlerts]);
      } catch (_) {
        // Chat alerts are supportive; the page-level API errors handle visible failures.
      }
    }

    loadLatestChats();
    const timer = window.setInterval(loadLatestChats, 2500);

    return () => {
      mounted = false;
      window.clearInterval(timer);
    };
  }, [onOpenChat]);

  if (!messageAlerts.length) return null;

  return (
    <ChatMessageAlert
      alert={messageAlerts[0]}
      onClose={() => setMessageAlerts((current) => current.slice(1))}
      onOpen={() => {
        setMessageAlerts((current) => current.slice(1));
        onOpenChat();
      }}
    />
  );
}

function notifyBrowserForGlobalChat(alert, onOpenChat) {
  if (!('Notification' in window) || Notification.permission !== 'granted') return;

  const userName = alert.conversation.user_name || 'App User';
  const body = alert.message.message || (hasChatImage(alert.message) ? 'Sent an image.' : 'Sent a new message.');
  const notification = new Notification(`New message from ${userName}`, {
    body,
    icon: '/favicon.ico',
    tag: `chat-message-${alert.id}`,
  });

  notification.onclick = () => {
    window.focus();
    onOpenChat();
    notification.close();
  };
}

function Dashboard({ onNavigate }) {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  async function loadDashboard() {
    setLoading(true);
    setError('');
    api.get('/admin/dashboard')
      .then((response) => setData(response.data))
      .catch((apiError) => setError(apiError.response?.data?.message || 'Could not load dashboard. Please check API URL or login again.'))
      .finally(() => setLoading(false));
  }

  useEffect(() => {
    loadDashboard();
  }, []);

  if (loading) return <LoadingBlock label="Loading dashboard..." />;
  if (error || !data?.stats) return <ErrorBlock message={error || 'Dashboard data is not available.'} />;

  const primaryStats = [
    ['Users', data.stats.users, `${data.stats.active_users || 0} active`, UsersRound, 'users'],
    ['Transaction Volume', formatMoney(data.stats.transaction_volume), `${data.stats.transactions || 0} requests`, BarChart3, 'recharges'],
    ['Pending Queue', data.stats.pending_transactions, 'Needs review', Activity, 'recharges'],
    ['Wallet Balance', formatMoney(data.stats.wallet_balance), 'User wallet total', CheckCircle2, 'users'],
  ];

  const moduleCards = [
    ['Mobile Recharge', data.transaction_modules?.mobile_recharge, Smartphone, 'recharges'],
    ['Bill Payment', data.transaction_modules?.bill_payment, ReceiptText, 'bills'],
    ['Bank Transfer', data.transaction_modules?.bank_transfer, Landmark, 'bank-transfers'],
    ['Wallet Withdrawal', data.transaction_modules?.wallet_withdrawal, Wallet, 'wallet-withdrawals'],
    ['Drive Offer', data.transaction_modules?.drive_offer, Wifi, 'drive-orders'],
  ];

  const queueCards = [
    ['Recharge', data.pending_queues?.recharges || 0, 'recharges', Smartphone],
    ['Bills', data.pending_queues?.bill_payments || 0, 'bills', ReceiptText],
    ['Bank', data.pending_queues?.bank_transfers || 0, 'bank-transfers', Landmark],
    ['Wallets', data.pending_queues?.wallet_withdrawals || 0, 'wallet-withdrawals', Wallet],
    ['Offers', data.pending_queues?.drive_offers || 0, 'drive-orders', Wifi],
    ['Chats', data.pending_queues?.chats || 0, 'chats', MessageCircle],
  ];

  return (
    <div className="space-y-6">
      <div className="overflow-hidden rounded-[16px] border border-slate-200 bg-slate-950 p-5 text-white shadow-sm">
        <div className="flex flex-col gap-5 lg:flex-row lg:items-center lg:justify-between">
          <div>
            <p className="text-xs uppercase tracking-[0.24em] text-red-300">Operations Overview</p>
            <h2 className="mt-2 text-2xl font-medium">City Go Remit Command Dashboard</h2>
            <p className="mt-2 max-w-2xl text-sm leading-6 text-slate-300">Monitor wallet activity, pending approvals, support pressure, notification reach and growth signals in one clean control room.</p>
          </div>
          <div className="grid grid-cols-2 gap-3 sm:flex">
            <QuickAction label="Users" icon={UsersRound} onClick={() => onNavigate('users')} />
            <QuickAction label="Chat" icon={MessageCircle} onClick={() => onNavigate('chats')} />
            <QuickAction label="Notify" icon={Bell} onClick={() => onNavigate('notifications')} />
          </div>
        </div>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {primaryStats.map(([label, value, hint, Icon, page]) => (
          <DashboardMetric key={label} label={label} value={value} hint={hint} icon={Icon} onClick={() => onNavigate(page)} />
        ))}
      </div>

      <div className="grid gap-6 xl:grid-cols-[1.35fr_.9fr]">
        <Panel title="7 Day Transaction Trend">
          <MiniTrendChart rows={data.daily_trend || []} />
        </Panel>
        <Panel title="Live Signals">
          <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-1">
            <SignalRow label="Open Chats" value={data.stats.open_chats || 0} icon={MessageCircle} action={() => onNavigate('chats')} />
            <SignalRow label="Active Devices" value={data.stats.active_devices || 0} icon={Bell} action={() => onNavigate('notifications')} />
            <SignalRow label="Active Banners" value={data.stats.active_banners || 0} icon={ImageIcon} action={() => onNavigate('banners')} />
            <SignalRow label="Unread App Alerts" value={data.stats.unread_notifications || 0} icon={Activity} action={() => onNavigate('notifications')} />
          </div>
        </Panel>
      </div>

      <div className="grid gap-6 xl:grid-cols-4">
        {moduleCards.map(([label, module, Icon, page]) => (
          <ModuleCard key={label} label={label} module={module || {}} icon={Icon} onClick={() => onNavigate(page)} />
        ))}
      </div>

      <div className="grid gap-6 xl:grid-cols-[.9fr_1.1fr]">
        <Panel title="Pending Work Queue">
          <div className="space-y-3">
            {queueCards.map(([label, value, page, Icon]) => (
              <QueueRow key={label} label={label} value={value} icon={Icon} onClick={() => onNavigate(page)} />
            ))}
          </div>
        </Panel>
        <Panel title="Recent Activity">
          <RecentActivityList rows={data.recent_activity || []} />
        </Panel>
      </div>

      <div className="grid gap-6 xl:grid-cols-2">
        <Panel title="Status Breakdown">
          <StatusBars breakdown={data.status_breakdown || {}} />
        </Panel>
        <Panel title="Newest Users">
          <DataList rows={data.recent_users || []} columns={['name', 'email', 'status']} />
        </Panel>
      </div>
    </div>
  );
}

function DashboardMetric({ label, value, hint, icon: Icon, onClick }) {
  return (
    <button onClick={onClick} className="rounded-[14px] border border-slate-200 bg-white p-5 text-left shadow-sm transition hover:-translate-y-0.5 hover:border-red-200 hover:shadow-md">
      <div className="flex items-center justify-between">
        <p className="text-sm text-slate-500">{label}</p>
        <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-red-50 text-red-600">
          <Icon size={20} />
        </span>
      </div>
      <p className="mt-4 text-3xl font-medium text-slate-950">{value}</p>
      <p className="mt-2 text-sm text-slate-500">{hint}</p>
    </button>
  );
}

function QuickAction({ label, icon: Icon, onClick }) {
  return (
    <button onClick={onClick} className="flex items-center justify-center gap-2 rounded-xl border border-white/10 bg-white/10 px-4 py-3 text-sm font-medium text-white transition hover:bg-white/15">
      <Icon size={17} />
      {label}
    </button>
  );
}

function MiniTrendChart({ rows }) {
  const safeRows = rows.length ? rows : [];
  const maxTransactions = Math.max(1, ...safeRows.map((item) => Number(item.transactions || 0)));
  const maxVolume = Math.max(1, ...safeRows.map((item) => Number(item.volume || 0)));
  const chartWidth = 680;
  const chartHeight = 260;
  const padding = { top: 24, right: 22, bottom: 44, left: 54 };
  const innerWidth = chartWidth - padding.left - padding.right;
  const innerHeight = chartHeight - padding.top - padding.bottom;
  const points = safeRows.map((item, index) => {
    const x = padding.left + (safeRows.length === 1 ? innerWidth / 2 : (index / (safeRows.length - 1)) * innerWidth);
    const y = padding.top + innerHeight - (Number(item.transactions || 0) / maxTransactions) * innerHeight;

    return { ...item, x, y };
  });
  const linePath = points.map((point, index) => `${index === 0 ? 'M' : 'L'} ${point.x} ${point.y}`).join(' ');
  const areaPath = points.length
    ? `${linePath} L ${points[points.length - 1].x} ${padding.top + innerHeight} L ${points[0].x} ${padding.top + innerHeight} Z`
    : '';
  const yLabels = [1, .75, .5, .25, 0].map((ratio) => ({
    value: Math.round(maxTransactions * ratio),
    y: padding.top + innerHeight - ratio * innerHeight,
  }));
  const activeTotal = safeRows.reduce((sum, item) => sum + Number(item.transactions || 0), 0);
  const activeVolume = safeRows.reduce((sum, item) => sum + Number(item.volume || 0), 0);
  const average = safeRows.length ? Math.round(activeTotal / safeRows.length) : 0;
  const bestDay = safeRows.reduce((best, item) => Number(item.transactions || 0) > Number(best.transactions || 0) ? item : best, safeRows[0] || {});
  const hasActivity = safeRows.some((item) => Number(item.transactions || 0) > 0 || Number(item.volume || 0) > 0);

  const [hovered, setHovered] = useState(null);

  const activePoint = hovered ?? (points.length ? points[points.length - 1] : null);

  return (
    <div className="space-y-4">
      <div className="overflow-hidden rounded-[14px] border border-slate-200 bg-white shadow-sm">
        <div className="flex flex-col gap-4 border-b border-slate-100 p-4 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <p className="text-xs uppercase tracking-[0.2em] text-red-600">Transaction Analytics</p>
            <h3 className="mt-1 text-lg font-medium text-slate-950">7-Day Performance</h3>
          </div>
          <div className="flex flex-wrap gap-2 text-xs">
            <span className="rounded-full border border-slate-200 bg-slate-50 px-3 py-1 font-medium text-slate-600">Requests</span>
            <span className="rounded-full border border-red-100 bg-red-50 px-3 py-1 font-medium text-red-600">Volume</span>
          </div>
        </div>

        <div className="grid gap-4 p-4 lg:grid-cols-[1fr_190px]">
          <div className="relative min-h-[300px] rounded-[12px] border border-slate-200 bg-slate-50 p-3">
            <svg viewBox={`0 0 ${chartWidth} ${chartHeight}`} className="h-[300px] w-full">
              <rect x="0" y="0" width={chartWidth} height={chartHeight} rx="18" fill="#f8fafc" />
              {yLabels.map((label) => (
                <g key={label.y}>
                  <line x1={padding.left} x2={chartWidth - padding.right} y1={label.y} y2={label.y} stroke="#e2e8f0" strokeWidth="1" />
                  <text x={padding.left - 12} y={label.y + 4} textAnchor="end" fontSize="11" fill="#94a3b8">{label.value}</text>
                </g>
              ))}
              {safeRows.map((item, index) => {
                const x = padding.left + (safeRows.length === 1 ? innerWidth / 2 : (index / (safeRows.length - 1)) * innerWidth);
                const barHeight = Math.max(hasActivity ? 4 : 10, (Number(item.volume || 0) / maxVolume) * (innerHeight * .7));
                return (
                  <rect
                    key={`bar-${item.date}`}
                    x={x - 14}
                    y={padding.top + innerHeight - barHeight}
                    width="28"
                    height={barHeight}
                    rx="8"
                    fill="#fee2e2"
                  />
                );
              })}
              {areaPath ? <path d={areaPath} fill="#fecaca" opacity=".45" /> : null}
              {linePath ? <path d={linePath} fill="none" stroke="#dc2626" strokeWidth="4" strokeLinecap="round" strokeLinejoin="round" /> : null}
              {points.map((point) => (
                <g key={`point-${point.date}`}>
                  <circle cx={point.x} cy={point.y} r="7" fill="#fff" stroke="#dc2626" strokeWidth="4" />
                  <circle cx={point.x} cy={point.y} r="18" fill="transparent" onMouseEnter={() => setHovered(point)} onMouseLeave={() => setHovered(null)} />
                </g>
              ))}
              {activePoint ? (
                <g>
                  <line x1={activePoint.x} x2={activePoint.x} y1={padding.top} y2={padding.top + innerHeight} stroke="#dc2626" strokeWidth="1.5" strokeDasharray="5 6" />
                  <rect x={Math.min(activePoint.x + 12, chartWidth - 190)} y={Math.max(activePoint.y - 56, 12)} width="170" height="58" rx="12" fill="#0f172a" />
                  <text x={Math.min(activePoint.x + 28, chartWidth - 174)} y={Math.max(activePoint.y - 32, 36)} fontSize="12" fill="#cbd5e1">{activePoint.date}</text>
                  <text x={Math.min(activePoint.x + 28, chartWidth - 174)} y={Math.max(activePoint.y - 12, 56)} fontSize="15" fontWeight="600" fill="#ffffff">{activePoint.transactions || 0} requests · {formatMoney(activePoint.volume || 0)}</text>
                </g>
              ) : null}
              {safeRows.map((item, index) => {
                const x = padding.left + (safeRows.length === 1 ? innerWidth / 2 : (index / (safeRows.length - 1)) * innerWidth);
                return <text key={`label-${item.date}`} x={x} y={chartHeight - 14} textAnchor="middle" fontSize="12" fill="#64748b">{item.date}</text>;
              })}
            </svg>
            {!hasActivity ? (
              <div className="absolute inset-x-6 top-8 rounded-xl border border-dashed border-slate-300 bg-white/90 px-4 py-4 text-center shadow-sm">
                <p className="text-sm font-medium text-slate-700">No transaction activity yet</p>
                <p className="mt-1 text-xs text-slate-500">Graph will become live once users submit recharge, bill, bank or offer requests.</p>
              </div>
            ) : null}
          </div>

          <div className="grid gap-3">
            <InsightStat label="Total Requests" value={activeTotal} />
            <InsightStat label="Total Volume" value={formatMoney(activeVolume)} />
            <InsightStat label="Daily Average" value={average} />
            <InsightStat label="Best Day" value={bestDay.date || '-'} />
          </div>
        </div>
      </div>
    </div>
  );
}

function InsightStat({ label, value }) {
  return (
    <div className="rounded-xl border border-slate-200 bg-slate-50 p-4">
      <p className="text-xs uppercase tracking-[0.16em] text-slate-500">{label}</p>
      <p className="mt-2 text-xl font-medium text-slate-950">{value}</p>
    </div>
  );
}

function SmallStat({ label, value }) {
  return (
    <div className="rounded-xl border border-slate-200 bg-white p-4">
      <p className="text-xs text-slate-500">{label}</p>
      <p className="mt-1 text-lg font-medium text-slate-950">{value}</p>
    </div>
  );
}

function SignalRow({ label, value, icon: Icon, action }) {
  return (
    <button onClick={action} className="flex items-center justify-between rounded-xl border border-slate-200 bg-slate-50 p-4 text-left transition hover:border-red-200 hover:bg-red-50">
      <span className="flex items-center gap-3">
        <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-white text-red-600">
          <Icon size={19} />
        </span>
        <span className="text-sm font-medium text-slate-800">{label}</span>
      </span>
      <span className="text-xl font-medium text-slate-950">{value}</span>
    </button>
  );
}

function ModuleCard({ label, module, icon: Icon, onClick }) {
  const total = Number(module.total || 0);
  const successful = Number(module.successful || 0);
  const successRate = total ? Math.round((successful / total) * 100) : 0;

  return (
    <button onClick={onClick} className="rounded-[14px] border border-slate-200 bg-white p-5 text-left shadow-sm transition hover:-translate-y-0.5 hover:shadow-md">
      <div className="flex items-center justify-between">
        <span className="flex h-11 w-11 items-center justify-center rounded-xl bg-slate-100 text-slate-800">
          <Icon size={20} />
        </span>
        <span className="rounded-full bg-emerald-50 px-3 py-1 text-xs font-medium text-emerald-700">{successRate}% success</span>
      </div>
      <h3 className="mt-4 font-medium text-slate-950">{label}</h3>
      <p className="mt-1 text-sm text-slate-500">{total} total · {module.pending || 0} pending</p>
      <div className="mt-4 h-2 overflow-hidden rounded-full bg-slate-100">
        <div className="h-full rounded-full bg-red-600" style={{ width: `${successRate}%` }} />
      </div>
      <p className="mt-3 text-sm font-medium text-slate-900">{formatMoney(module.volume || 0)}</p>
    </button>
  );
}

function QueueRow({ label, value, icon: Icon, onClick }) {
  const urgent = Number(value || 0) > 0;

  return (
    <button onClick={onClick} className={`flex w-full items-center justify-between rounded-xl border p-4 text-left transition ${urgent ? 'border-red-200 bg-red-50' : 'border-slate-200 bg-slate-50 hover:bg-white'}`}>
      <span className="flex items-center gap-3">
        <span className={`flex h-10 w-10 items-center justify-center rounded-xl ${urgent ? 'bg-white text-red-600' : 'bg-white text-slate-500'}`}>
          <Icon size={19} />
        </span>
        <span>
          <span className="block text-sm font-medium text-slate-900">{label}</span>
          <span className="text-xs text-slate-500">{urgent ? 'Waiting for admin action' : 'All clear'}</span>
        </span>
      </span>
      <span className={`rounded-full px-3 py-1 text-sm font-medium ${urgent ? 'bg-red-600 text-white' : 'bg-emerald-50 text-emerald-700'}`}>{value}</span>
    </button>
  );
}

function RecentActivityList({ rows }) {
  if (!rows.length) {
    return <p className="rounded-xl border border-slate-200 bg-slate-50 p-5 text-sm text-slate-500">No recent activity yet.</p>;
  }

  return (
    <div className="space-y-3">
      {rows.map((item) => (
        <div key={item.id} className="rounded-xl border border-slate-200 bg-slate-50 p-4">
          <div className="flex items-start justify-between gap-3">
            <div className="min-w-0">
              <p className="font-medium text-slate-950">{item.type}</p>
              <p className="mt-1 truncate text-xs text-slate-500">{item.reference} · {item.email}</p>
            </div>
            <StatusBadge status={item.status} />
          </div>
          <div className="mt-3 flex items-center justify-between text-sm">
            <span className="font-medium text-slate-900">{formatMoney(item.amount || 0)}</span>
            <span className="text-slate-500">{formatDate(item.created_at)}</span>
          </div>
        </div>
      ))}
    </div>
  );
}

function StatusBars({ breakdown }) {
  const rows = Object.entries(breakdown).filter(([, value]) => Number(value || 0) >= 0);
  const max = Math.max(1, ...rows.map(([, value]) => Number(value || 0)));

  return (
    <div className="space-y-4">
      {rows.map(([label, value]) => {
        const width = Math.max(4, (Number(value || 0) / max) * 100);
        return (
          <div key={label}>
            <div className="mb-2 flex items-center justify-between text-sm">
              <span className="font-medium text-slate-700">{titleCase(label)}</span>
              <span className="text-slate-500">{value}</span>
            </div>
            <div className="h-2 overflow-hidden rounded-full bg-slate-100">
              <div className="h-full rounded-full bg-red-600" style={{ width: `${width}%` }} />
            </div>
          </div>
        );
      })}
    </div>
  );
}

function RechargesPage() {
  const [data, setData] = useState(null);
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState('');
  const [operator, setOperator] = useState('');
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [notice, setNotice] = useState('');
  const [error, setError] = useState('');

  const query = useMemo(() => ({ search, status, operator }), [search, status, operator]);

  async function loadRecharges() {
    setLoading(true);
    try {
      const response = await api.get('/admin/recharges', { params: query });
      setData(response.data);
    } catch (apiError) {
      setError(apiError.response?.data?.message || 'Could not load recharge transactions.');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadRecharges();
  }, [query]);

  function openEdit(recharge) {
    setEditing(recharge);
    setForm({
      email: recharge.email || '',
      mobile_number: recharge.mobile_number || '',
      operator: recharge.operator || 'Grameenphone',
      amount: recharge.amount || '',
      charge: recharge.charge || '0',
      status: recharge.status || 'pending',
      admin_note: recharge.admin_note || '',
    });
    setError('');
    setNotice('');
  }

  async function quickStatus(recharge, nextStatus) {
    setSaving(true);
    setError('');

    try {
      await api.put(`/admin/recharges/${recharge.id}`, {
        email: recharge.email,
        mobile_number: recharge.mobile_number,
        operator: recharge.operator,
        amount: recharge.amount,
        charge: recharge.charge || '0',
        status: nextStatus,
        admin_note: recharge.admin_note || `Marked as ${nextStatus} by admin.`,
      });
      setNotice(`Transaction marked as ${nextStatus}.`);
      await loadRecharges();
    } catch (apiError) {
      setError(apiError.response?.data?.message || 'Could not update transaction status.');
    } finally {
      setSaving(false);
    }
  }

  async function saveEdit(event) {
    event.preventDefault();
    setSaving(true);
    setError('');

    try {
      const response = await api.put(`/admin/recharges/${editing.id}`, form);
      setNotice(response.data.message);
      setEditing(null);
      setForm(null);
      await loadRecharges();
    } catch (apiError) {
      const errors = apiError.response?.data?.errors;
      setError(errors ? Object.values(errors).flat()[0] : (apiError.response?.data?.message || 'Could not save transaction.'));
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="space-y-6">
      <div className="rounded-[14px] border border-slate-200 bg-white p-5 shadow-sm">
        <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
          <div>
            <h2 className="text-lg font-medium text-slate-950">Recharge Transaction Management</h2>
            <p className="mt-1 text-sm text-slate-500">Monitor recharge requests, update status and correct transaction details safely.</p>
          </div>
          <div className="rounded-xl border border-red-100 bg-red-50 px-4 py-3 text-sm font-medium text-red-700">
            Live API Records
          </div>
        </div>
      </div>

      {notice ? <div className="rounded-xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-700">{notice}</div> : null}
      {error ? <div className="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">{error}</div> : null}

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-6">
        {data ? Object.entries(data.stats).map(([key, value]) => (
          <div key={key} className="rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
            <p className="text-xs uppercase tracking-[0.18em] text-slate-400">{key.replace('_', ' ')}</p>
            <p className="mt-2 text-2xl font-medium">{key === 'volume' ? formatMoney(value) : value}</p>
          </div>
        )) : null}
      </div>

      <div>
        <Panel title="Transactions">
          <div className="mb-4 grid gap-3 lg:grid-cols-[1fr_180px_180px]">
            <div className="flex items-center gap-2 rounded-xl border border-slate-200 bg-slate-50 px-4">
              <Search size={18} className="text-slate-400" />
              <input value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Search transaction, email or mobile" className="h-12 w-full bg-transparent text-sm outline-none" />
            </div>
            <select value={status} onChange={(event) => setStatus(event.target.value)} className="h-12 rounded-xl border border-slate-200 bg-slate-50 px-4 text-sm outline-none">
              <option value="">All Status</option>
              {(data?.statuses || []).map((item) => <option key={item} value={item}>{titleCase(item)}</option>)}
            </select>
            <select value={operator} onChange={(event) => setOperator(event.target.value)} className="h-12 rounded-xl border border-slate-200 bg-slate-50 px-4 text-sm outline-none">
              <option value="">All Operators</option>
              {(data?.operators || []).map((item) => <option key={item} value={item}>{item}</option>)}
            </select>
          </div>

          {loading ? <LoadingBlock label="Loading recharge transactions..." /> : !data?.recharges ? (
            <ErrorBlock message="Recharge transactions are not available." />
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full min-w-[980px] text-left text-sm">
                <thead>
                  <tr className="border-b border-slate-200 text-xs uppercase tracking-[0.16em] text-slate-400">
                    <th className="py-3">Transaction</th>
                    <th className="py-3">Customer</th>
                    <th className="py-3">Mobile</th>
                    <th className="py-3">Operator</th>
                    <th className="py-3">Total</th>
                    <th className="py-3">Status</th>
                    <th className="py-3 text-right">Manage</th>
                  </tr>
                </thead>
                <tbody>
                  {data.recharges.data.map((recharge) => (
                    <tr key={recharge.id} className="border-b border-slate-100">
                      <td className="py-4">
                        <p className="font-medium text-slate-900">{recharge.transaction_id}</p>
                        <p className="text-xs text-slate-500">{formatDate(recharge.created_at)}</p>
                      </td>
                      <td className="py-4">
                        <p className="text-slate-900">{recharge.user?.name || 'App User'}</p>
                        <p className="text-xs text-slate-500">{recharge.email}</p>
                      </td>
                      <td className="py-4 text-slate-600">{recharge.mobile_number}</td>
                      <td className="py-4 text-slate-600">{recharge.operator}</td>
                      <td className="py-4">
                        <p className="font-medium text-slate-900">{formatMoney(recharge.total_amount || recharge.amount)}</p>
                        <p className="text-xs text-slate-500">Charge {formatMoney(recharge.charge || 0)}</p>
                      </td>
                      <td className="py-4"><StatusBadge status={recharge.status} /></td>
                      <td className="py-4">
                        <div className="flex justify-end gap-2">
                          <button disabled={saving} onClick={() => quickStatus(recharge, 'successful')} className="rounded-xl border border-emerald-200 px-3 py-2 text-xs text-emerald-700 hover:bg-emerald-50">Success</button>
                          <button disabled={saving} onClick={() => quickStatus(recharge, 'failed')} className="rounded-xl border border-red-200 px-3 py-2 text-xs text-red-700 hover:bg-red-50">Fail</button>
                          <button onClick={() => openEdit(recharge)} className="rounded-xl border border-slate-200 p-2 text-slate-600 hover:bg-slate-50"><Edit3 size={16} /></button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </Panel>
      </div>

      {editing && form ? (
        <EditRechargeModal
          data={data}
          editing={editing}
          form={form}
          saving={saving}
          setForm={setForm}
          onClose={() => { setEditing(null); setForm(null); }}
          onSubmit={saveEdit}
        />
      ) : null}
    </div>
  );
}

function EditRechargeModal({ data, editing, form, saving, setForm, onClose, onSubmit }) {
  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-slate-950/45 p-3 sm:items-center">
      <form onSubmit={onSubmit} className="max-h-[92vh] w-full max-w-2xl overflow-y-auto rounded-[14px] border border-slate-200 bg-white p-5 shadow-sm">
        <div className="flex items-start justify-between gap-4">
          <div>
            <p className="text-xs uppercase tracking-[0.22em] text-red-600">Recharge Management</p>
            <h3 className="mt-2 text-xl font-medium text-slate-950">Edit Transaction</h3>
            <p className="mt-1 text-sm text-slate-500">{editing.transaction_id}</p>
          </div>
          <button type="button" onClick={onClose} className="rounded-xl border border-slate-200 p-2 text-slate-500 hover:bg-slate-50">
            <X size={18} />
          </button>
        </div>

        <div className="mt-5 grid gap-4 md:grid-cols-2">
          <Field label="Customer Email" type="email" value={form.email} onChange={(email) => setForm({ ...form, email })} required />
          <Field label="Mobile Number" value={form.mobile_number} onChange={(mobile_number) => setForm({ ...form, mobile_number })} required />
          <label className="block">
            <span className="mb-2 block text-sm font-medium text-slate-700">Operator</span>
            <select value={form.operator} onChange={(event) => setForm({ ...form, operator: event.target.value })} className="h-12 w-full rounded-xl border border-slate-200 bg-slate-50 px-4 text-sm outline-none">
              {(data?.operators || []).map((item) => <option key={item} value={item}>{item}</option>)}
            </select>
          </label>
          <Field label="Amount" type="number" value={form.amount} onChange={(amount) => setForm({ ...form, amount })} required />
          <Field label="Charge" type="number" value={form.charge} onChange={(charge) => setForm({ ...form, charge })} />
          <label className="block">
            <span className="mb-2 block text-sm font-medium text-slate-700">Status</span>
            <select value={form.status} onChange={(event) => setForm({ ...form, status: event.target.value })} className="h-12 w-full rounded-xl border border-slate-200 bg-slate-50 px-4 text-sm outline-none">
              {(data?.statuses || []).map((item) => <option key={item} value={item}>{titleCase(item)}</option>)}
            </select>
          </label>
          <div className="rounded-xl border border-slate-200 bg-slate-50 p-4">
            <p className="text-xs uppercase tracking-[0.18em] text-slate-400">Current Status</p>
            <div className="mt-2"><StatusBadge status={editing.status} /></div>
          </div>
        </div>

        <label className="mt-4 block">
          <span className="mb-2 block text-sm font-medium text-slate-700">Admin Note</span>
          <textarea value={form.admin_note} onChange={(event) => setForm({ ...form, admin_note: event.target.value })} rows="4" className="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm outline-none focus:border-red-400" placeholder="Write a short internal note for this transaction." />
        </label>

        <div className="mt-5 flex flex-col-reverse gap-3 sm:flex-row sm:justify-end">
          <button type="button" onClick={onClose} className="rounded-xl border border-slate-200 px-5 py-3 text-sm text-slate-600 hover:bg-slate-50">
            Cancel
          </button>
          <button disabled={saving} className="rounded-xl bg-red-600 px-5 py-3 text-sm font-medium text-white hover:bg-red-700 disabled:opacity-60">
            {saving ? 'Saving...' : 'Save Transaction'}
          </button>
        </div>
      </form>
    </div>
  );
}

function BillPaymentsPage() {
  const [data, setData] = useState(null);
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState('');
  const [category, setCategory] = useState('');
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [notice, setNotice] = useState('');
  const [error, setError] = useState('');

  const query = useMemo(() => ({ search, status, category }), [search, status, category]);

  async function loadBills() {
    setLoading(true);
    try {
      const response = await api.get('/admin/bill-payments', { params: query });
      setData(response.data);
    } catch (apiError) {
      setError(apiError.response?.data?.message || 'Could not load bill payments.');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadBills();
  }, [query]);

  function openEdit(item) {
    setEditing(item);
    setForm({
      category: item.category || 'electricity',
      provider: item.provider || '',
      bill_type: item.bill_type || '',
      account_number: item.account_number || '',
      contact_number: item.contact_number || '',
      billing_period: item.billing_period || '',
      amount: item.amount || '',
      charge: item.charge || '0',
      status: item.status || 'pending',
      admin_note: item.admin_note || '',
    });
    setError('');
  }

  async function quickStatus(item, nextStatus) {
    setSaving(true);
    setError('');
    try {
      await api.put(`/admin/bill-payments/${item.id}`, {
        category: item.category,
        provider: item.provider,
        bill_type: item.bill_type || '',
        account_number: item.account_number,
        contact_number: item.contact_number || '',
        billing_period: item.billing_period || '',
        amount: item.amount,
        charge: item.charge || '0',
        status: nextStatus,
        admin_note: item.admin_note || `Marked as ${nextStatus} by admin.`,
      });
      setNotice(`Bill payment marked as ${nextStatus}.`);
      await loadBills();
    } catch (apiError) {
      const errors = apiError.response?.data?.errors;
      setError(errors ? Object.values(errors).flat()[0] : (apiError.response?.data?.message || 'Could not update bill payment.'));
    } finally {
      setSaving(false);
    }
  }

  async function saveEdit(event) {
    event.preventDefault();
    setSaving(true);
    setError('');
    try {
      const response = await api.put(`/admin/bill-payments/${editing.id}`, form);
      setNotice(response.data.message);
      setEditing(null);
      setForm(null);
      await loadBills();
    } catch (apiError) {
      const errors = apiError.response?.data?.errors;
      setError(errors ? Object.values(errors).flat()[0] : (apiError.response?.data?.message || 'Could not save bill payment.'));
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="space-y-6">
      <div className="rounded-[14px] border border-slate-200 bg-white p-5 shadow-sm">
        <h2 className="text-lg font-medium text-slate-950">Bill Payment Management</h2>
        <p className="mt-1 text-sm text-slate-500">Review OTP-confirmed bill requests, approve payments and debit wallet balance safely.</p>
      </div>

      {notice ? <div className="rounded-xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-700">{notice}</div> : null}
      {error ? <div className="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">{error}</div> : null}

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-5">
        {data ? Object.entries(data.stats).map(([key, value]) => (
          <div key={key} className="rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
            <p className="text-xs uppercase tracking-[0.18em] text-slate-400">{key.replace('_', ' ')}</p>
            <p className="mt-2 text-2xl font-medium">{key === 'volume' ? formatMoney(value) : value}</p>
          </div>
        )) : null}
      </div>

      <Panel title="Bill Requests">
        <div className="mb-4 grid gap-3 lg:grid-cols-[1fr_180px_180px]">
          <div className="flex items-center gap-2 rounded-xl border border-slate-200 bg-slate-50 px-4">
            <Search size={18} className="text-slate-400" />
            <input value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Search transaction, provider or account" className="h-12 w-full bg-transparent text-sm outline-none" />
          </div>
          <select value={status} onChange={(event) => setStatus(event.target.value)} className="h-12 rounded-xl border border-slate-200 bg-slate-50 px-4 text-sm outline-none">
            <option value="">All Status</option>
            {(data?.statuses || []).map((item) => <option key={item} value={item}>{titleCase(item)}</option>)}
          </select>
          <select value={category} onChange={(event) => setCategory(event.target.value)} className="h-12 rounded-xl border border-slate-200 bg-slate-50 px-4 text-sm outline-none">
            <option value="">All Categories</option>
            {(data?.categories || []).map((item) => <option key={item} value={item}>{titleCase(item)}</option>)}
          </select>
        </div>

        {loading ? <LoadingBlock label="Loading bill payments..." /> : !data?.bill_payments ? (
          <ErrorBlock message="Bill payments are not available." />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full min-w-[1100px] text-left text-sm">
              <thead>
                <tr className="border-b border-slate-200 text-xs uppercase tracking-[0.16em] text-slate-400">
                  <th className="py-3">Transaction</th>
                  <th className="py-3">Customer</th>
                  <th className="py-3">Bill</th>
                  <th className="py-3">Account</th>
                  <th className="py-3">Total</th>
                  <th className="py-3">Status</th>
                  <th className="py-3 text-right">Manage</th>
                </tr>
              </thead>
              <tbody>
                {data.bill_payments.data.map((item) => (
                  <tr key={item.id} className="border-b border-slate-100">
                    <td className="py-4">
                      <p className="font-medium text-slate-900">{item.transaction_id}</p>
                      <p className="text-xs text-slate-500">{formatDate(item.created_at)}</p>
                    </td>
                    <td className="py-4">
                      <p className="text-slate-900">{item.user?.name || 'App User'}</p>
                      <p className="text-xs text-slate-500">{item.email}</p>
                    </td>
                    <td className="py-4">
                      <p className="font-medium text-slate-900">{item.provider}</p>
                      <p className="text-xs text-slate-500">{titleCase(item.category)} · {item.bill_type || 'Bill'}</p>
                    </td>
                    <td className="py-4 text-slate-600">{item.account_number}</td>
                    <td className="py-4 font-medium text-slate-900">{formatMoney(item.total_amount)}</td>
                    <td className="py-4"><StatusBadge status={item.status} /></td>
                    <td className="py-4">
                      <div className="flex justify-end gap-2">
                        <button disabled={saving} onClick={() => quickStatus(item, 'successful')} className="rounded-xl border border-emerald-200 px-3 py-2 text-xs text-emerald-700 hover:bg-emerald-50">Approve</button>
                        <button disabled={saving} onClick={() => quickStatus(item, 'failed')} className="rounded-xl border border-red-200 px-3 py-2 text-xs text-red-700 hover:bg-red-50">Fail</button>
                        <button onClick={() => openEdit(item)} className="rounded-xl border border-slate-200 p-2 text-slate-600 hover:bg-slate-50"><Edit3 size={16} /></button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Panel>

      {editing && form ? (
        <BillEditModal
          data={data}
          form={form}
          saving={saving}
          setForm={setForm}
          onClose={() => { setEditing(null); setForm(null); }}
          onSubmit={saveEdit}
        />
      ) : null}
    </div>
  );
}

function BillEditModal({ data, form, saving, setForm, onClose, onSubmit }) {
  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-slate-950/45 p-3 sm:items-center">
      <form onSubmit={onSubmit} className="max-h-[92vh] w-full max-w-2xl overflow-y-auto rounded-[14px] border border-slate-200 bg-white p-5 shadow-sm">
        <div className="flex items-start justify-between gap-4">
          <div>
            <p className="text-xs uppercase tracking-[0.22em] text-red-600">Bill Payment</p>
            <h3 className="mt-2 text-xl font-medium text-slate-950">Edit Bill Request</h3>
          </div>
          <button type="button" onClick={onClose} className="rounded-xl border border-slate-200 p-2 text-slate-500 hover:bg-slate-50"><X size={18} /></button>
        </div>
        <div className="mt-5 grid gap-4 md:grid-cols-2">
          <select value={form.category} onChange={(event) => setForm({ ...form, category: event.target.value })} className="h-12 rounded-xl border border-slate-200 bg-slate-50 px-4 text-sm outline-none">
            {(data?.categories || []).map((item) => <option key={item} value={item}>{titleCase(item)}</option>)}
          </select>
          <Field label="Provider" value={form.provider} onChange={(provider) => setForm({ ...form, provider })} required />
          <Field label="Bill Type" value={form.bill_type} onChange={(bill_type) => setForm({ ...form, bill_type })} />
          <Field label="Account Number" value={form.account_number} onChange={(account_number) => setForm({ ...form, account_number })} required />
          <Field label="Contact Number" value={form.contact_number} onChange={(contact_number) => setForm({ ...form, contact_number })} />
          <Field label="Billing Period" value={form.billing_period} onChange={(billing_period) => setForm({ ...form, billing_period })} />
          <Field label="Amount" type="number" value={form.amount} onChange={(amount) => setForm({ ...form, amount })} required />
          <Field label="Charge" type="number" value={form.charge} onChange={(charge) => setForm({ ...form, charge })} />
          <select value={form.status} onChange={(event) => setForm({ ...form, status: event.target.value })} className="h-12 rounded-xl border border-slate-200 bg-slate-50 px-4 text-sm outline-none">
            {(data?.statuses || []).map((item) => <option key={item} value={item}>{titleCase(item)}</option>)}
          </select>
        </div>
        <label className="mt-4 block">
          <span className="mb-2 block text-sm font-medium text-slate-700">Admin Note</span>
          <textarea value={form.admin_note} onChange={(event) => setForm({ ...form, admin_note: event.target.value })} rows="4" className="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm outline-none" />
        </label>
        <div className="mt-5 flex justify-end gap-3">
          <button type="button" onClick={onClose} className="rounded-xl border border-slate-200 px-5 py-3 text-sm text-slate-600 hover:bg-slate-50">Cancel</button>
          <button disabled={saving} className="rounded-xl bg-red-600 px-5 py-3 text-sm font-medium text-white hover:bg-red-700 disabled:opacity-60">{saving ? 'Saving...' : 'Save Bill'}</button>
        </div>
      </form>
    </div>
  );
}

function BankTransfersPage() {
  const [data, setData] = useState(null);
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState('');
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [notice, setNotice] = useState('');
  const [error, setError] = useState('');

  const query = useMemo(() => ({ search, status }), [search, status]);

  async function loadTransfers() {
    setLoading(true);
    try {
      const response = await api.get('/admin/bank-transfers', { params: query });
      setData(response.data);
    } catch (apiError) {
      setError(apiError.response?.data?.message || 'Could not load bank transfers.');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadTransfers();
  }, [query]);

  function openEdit(item) {
    setEditing(item);
    setForm({
      bank_name: item.bank_name || '',
      branch_name: item.branch_name || '',
      account_name: item.account_name || '',
      account_number: item.account_number || '',
      routing_number: item.routing_number || '',
      contact_number: item.contact_number || '',
      amount: item.amount || '',
      charge: item.charge || '0',
      status: item.status || 'pending',
      admin_note: item.admin_note || '',
    });
    setError('');
  }

  async function quickStatus(item, nextStatus) {
    setSaving(true);
    setError('');
    try {
      await api.put(`/admin/bank-transfers/${item.id}`, {
        bank_name: item.bank_name,
        branch_name: item.branch_name || '',
        account_name: item.account_name,
        account_number: item.account_number,
        routing_number: item.routing_number || '',
        contact_number: item.contact_number || '',
        amount: item.amount,
        charge: item.charge || '0',
        status: nextStatus,
        admin_note: item.admin_note || `Marked as ${nextStatus} by admin.`,
      });
      setNotice(`Bank transfer marked as ${nextStatus}.`);
      await loadTransfers();
    } catch (apiError) {
      const errors = apiError.response?.data?.errors;
      setError(errors ? Object.values(errors).flat()[0] : (apiError.response?.data?.message || 'Could not update bank transfer.'));
    } finally {
      setSaving(false);
    }
  }

  async function saveEdit(event) {
    event.preventDefault();
    setSaving(true);
    setError('');
    try {
      const response = await api.put(`/admin/bank-transfers/${editing.id}`, form);
      setNotice(response.data.message);
      setEditing(null);
      setForm(null);
      await loadTransfers();
    } catch (apiError) {
      const errors = apiError.response?.data?.errors;
      setError(errors ? Object.values(errors).flat()[0] : (apiError.response?.data?.message || 'Could not save bank transfer.'));
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="space-y-6">
      <div className="rounded-[14px] border border-slate-200 bg-white p-5 shadow-sm">
        <h2 className="text-lg font-medium text-slate-950">Bank Transfer Management</h2>
        <p className="mt-1 text-sm text-slate-500">Process OTP-confirmed bank withdrawal requests, approve transfers and refund failed requests safely.</p>
      </div>

      {notice ? <div className="rounded-xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-700">{notice}</div> : null}
      {error ? <div className="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">{error}</div> : null}

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-5">
        {data ? Object.entries(data.stats).map(([key, value]) => (
          <div key={key} className="rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
            <p className="text-xs uppercase tracking-[0.18em] text-slate-400">{key.replace('_', ' ')}</p>
            <p className="mt-2 text-2xl font-medium">{key === 'volume' ? formatMoney(value) : value}</p>
          </div>
        )) : null}
      </div>

      <Panel title="Bank Transfer Requests">
        <div className="mb-4 grid gap-3 lg:grid-cols-[1fr_180px]">
          <div className="flex items-center gap-2 rounded-xl border border-slate-200 bg-slate-50 px-4">
            <Search size={18} className="text-slate-400" />
            <input value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Search transaction, bank, account or email" className="h-12 w-full bg-transparent text-sm outline-none" />
          </div>
          <select value={status} onChange={(event) => setStatus(event.target.value)} className="h-12 rounded-xl border border-slate-200 bg-slate-50 px-4 text-sm outline-none">
            <option value="">All Status</option>
            {(data?.statuses || []).map((item) => <option key={item} value={item}>{titleCase(item)}</option>)}
          </select>
        </div>

        {loading ? <LoadingBlock label="Loading bank transfers..." /> : !data?.bank_transfers ? (
          <ErrorBlock message="Bank transfers are not available." />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full min-w-[1100px] text-left text-sm">
              <thead>
                <tr className="border-b border-slate-200 text-xs uppercase tracking-[0.16em] text-slate-400">
                  <th className="py-3">Transaction</th>
                  <th className="py-3">Customer</th>
                  <th className="py-3">Bank</th>
                  <th className="py-3">Account</th>
                  <th className="py-3">Total</th>
                  <th className="py-3">Status</th>
                  <th className="py-3 text-right">Manage</th>
                </tr>
              </thead>
              <tbody>
                {data.bank_transfers.data.map((item) => (
                  <tr key={item.id} className="border-b border-slate-100">
                    <td className="py-4">
                      <p className="font-medium text-slate-900">{item.transaction_id}</p>
                      <p className="text-xs text-slate-500">{formatDate(item.created_at)}</p>
                    </td>
                    <td className="py-4">
                      <p className="text-slate-900">{item.user?.name || 'App User'}</p>
                      <p className="text-xs text-slate-500">{item.email}</p>
                    </td>
                    <td className="py-4">
                      <p className="font-medium text-slate-900">{item.bank_name}</p>
                      <p className="text-xs text-slate-500">{item.branch_name || 'Branch not set'}</p>
                    </td>
                    <td className="py-4">
                      <p className="text-slate-900">{item.account_name}</p>
                      <p className="text-xs text-slate-500">{item.account_number}</p>
                    </td>
                    <td className="py-4 font-medium text-slate-900">{formatMoney(item.total_amount)}</td>
                    <td className="py-4"><StatusBadge status={item.status} /></td>
                    <td className="py-4">
                      <div className="flex justify-end gap-2">
                        <button disabled={saving} onClick={() => quickStatus(item, 'successful')} className="rounded-xl border border-emerald-200 px-3 py-2 text-xs text-emerald-700 hover:bg-emerald-50">Approve</button>
                        <button disabled={saving} onClick={() => quickStatus(item, 'failed')} className="rounded-xl border border-red-200 px-3 py-2 text-xs text-red-700 hover:bg-red-50">Fail</button>
                        <button onClick={() => openEdit(item)} className="rounded-xl border border-slate-200 p-2 text-slate-600 hover:bg-slate-50"><Edit3 size={16} /></button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Panel>

      {editing && form ? (
        <BankTransferEditModal
          data={data}
          form={form}
          saving={saving}
          setForm={setForm}
          onClose={() => { setEditing(null); setForm(null); }}
          onSubmit={saveEdit}
        />
      ) : null}
    </div>
  );
}

function BankTransferEditModal({ data, form, saving, setForm, onClose, onSubmit }) {
  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-slate-950/45 p-3 sm:items-center">
      <form onSubmit={onSubmit} className="max-h-[92vh] w-full max-w-2xl overflow-y-auto rounded-[14px] border border-slate-200 bg-white p-5 shadow-sm">
        <div className="flex items-start justify-between gap-4">
          <div>
            <p className="text-xs uppercase tracking-[0.22em] text-red-600">Bank Transfer</p>
            <h3 className="mt-2 text-xl font-medium text-slate-950">Edit Transfer Request</h3>
          </div>
          <button type="button" onClick={onClose} className="rounded-xl border border-slate-200 p-2 text-slate-500 hover:bg-slate-50"><X size={18} /></button>
        </div>
        <div className="mt-5 grid gap-4 md:grid-cols-2">
          <Field label="Bank Name" value={form.bank_name} onChange={(bank_name) => setForm({ ...form, bank_name })} required />
          <Field label="Branch Name" value={form.branch_name} onChange={(branch_name) => setForm({ ...form, branch_name })} />
          <Field label="Account Name" value={form.account_name} onChange={(account_name) => setForm({ ...form, account_name })} required />
          <Field label="Account Number" value={form.account_number} onChange={(account_number) => setForm({ ...form, account_number })} required />
          <Field label="Routing Number" value={form.routing_number} onChange={(routing_number) => setForm({ ...form, routing_number })} />
          <Field label="Contact Number" value={form.contact_number} onChange={(contact_number) => setForm({ ...form, contact_number })} />
          <Field label="Amount" type="number" value={form.amount} onChange={(amount) => setForm({ ...form, amount })} required />
          <Field label="Charge" type="number" value={form.charge} onChange={(charge) => setForm({ ...form, charge })} />
          <select value={form.status} onChange={(event) => setForm({ ...form, status: event.target.value })} className="h-12 rounded-xl border border-slate-200 bg-slate-50 px-4 text-sm outline-none">
            {(data?.statuses || []).map((item) => <option key={item} value={item}>{titleCase(item)}</option>)}
          </select>
        </div>
        <label className="mt-4 block">
          <span className="mb-2 block text-sm font-medium text-slate-700">Admin Note</span>
          <textarea value={form.admin_note} onChange={(event) => setForm({ ...form, admin_note: event.target.value })} rows="4" className="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm outline-none" />
        </label>
        <div className="mt-5 flex justify-end gap-3">
          <button type="button" onClick={onClose} className="rounded-xl border border-slate-200 px-5 py-3 text-sm text-slate-600 hover:bg-slate-50">Cancel</button>
          <button disabled={saving} className="rounded-xl bg-red-600 px-5 py-3 text-sm font-medium text-white hover:bg-red-700 disabled:opacity-60">{saving ? 'Saving...' : 'Save Transfer'}</button>
        </div>
      </form>
    </div>
  );
}

function WalletWithdrawalsPage() {
  const [data, setData] = useState(null);
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState('');
  const [provider, setProvider] = useState('');
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [notice, setNotice] = useState('');
  const [error, setError] = useState('');

  const query = useMemo(() => ({ search, status, wallet_provider: provider }), [search, status, provider]);

  async function loadWithdrawals() {
    setLoading(true);
    try {
      const response = await api.get('/admin/wallet-withdrawals', { params: query });
      setData(response.data);
    } catch (apiError) {
      setError(apiError.response?.data?.message || 'Could not load wallet withdrawals.');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadWithdrawals();
  }, [query]);

  function openEdit(item) {
    setEditing(item);
    setForm({
      wallet_provider: item.wallet_provider || 'bKash',
      wallet_number: item.wallet_number || '',
      account_name: item.account_name || '',
      contact_number: item.contact_number || '',
      amount: item.amount || '',
      charge: item.charge || '0',
      status: item.status || 'pending',
      admin_note: item.admin_note || '',
    });
    setError('');
  }

  async function quickStatus(item, nextStatus) {
    setSaving(true);
    setError('');
    try {
      await api.put(`/admin/wallet-withdrawals/${item.id}`, {
        wallet_provider: item.wallet_provider,
        wallet_number: item.wallet_number,
        account_name: item.account_name || '',
        contact_number: item.contact_number || '',
        amount: item.amount,
        charge: item.charge || '0',
        status: nextStatus,
        admin_note: item.admin_note || `Marked as ${nextStatus} by admin.`,
      });
      setNotice(`Wallet withdrawal marked as ${nextStatus}.`);
      await loadWithdrawals();
    } catch (apiError) {
      const errors = apiError.response?.data?.errors;
      setError(errors ? Object.values(errors).flat()[0] : (apiError.response?.data?.message || 'Could not update wallet withdrawal.'));
    } finally {
      setSaving(false);
    }
  }

  async function saveEdit(event) {
    event.preventDefault();
    setSaving(true);
    setError('');
    try {
      const response = await api.put(`/admin/wallet-withdrawals/${editing.id}`, form);
      setNotice(response.data.message);
      setEditing(null);
      setForm(null);
      await loadWithdrawals();
    } catch (apiError) {
      const errors = apiError.response?.data?.errors;
      setError(errors ? Object.values(errors).flat()[0] : (apiError.response?.data?.message || 'Could not save wallet withdrawal.'));
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="space-y-6">
      <div className="rounded-[14px] border border-slate-200 bg-white p-5 shadow-sm">
        <h2 className="text-lg font-medium text-slate-950">Wallet Withdrawal Management</h2>
        <p className="mt-1 text-sm text-slate-500">Process bKash, Nagad and Rocket withdrawal requests, approve payouts and refund failed requests safely.</p>
      </div>

      {notice ? <div className="rounded-xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-700">{notice}</div> : null}
      {error ? <div className="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">{error}</div> : null}

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-5">
        {data ? Object.entries(data.stats).map(([key, value]) => (
          <div key={key} className="rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
            <p className="text-xs uppercase tracking-[0.18em] text-slate-400">{key.replace('_', ' ')}</p>
            <p className="mt-2 text-2xl font-medium">{key === 'volume' ? formatMoney(value) : value}</p>
          </div>
        )) : null}
      </div>

      <Panel title="Wallet Withdrawal Requests">
        <div className="mb-4 grid gap-3 lg:grid-cols-[1fr_170px_170px]">
          <div className="flex items-center gap-2 rounded-xl border border-slate-200 bg-slate-50 px-4">
            <Search size={18} className="text-slate-400" />
            <input value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Search transaction, wallet, number or email" className="h-12 w-full bg-transparent text-sm outline-none" />
          </div>
          <select value={provider} onChange={(event) => setProvider(event.target.value)} className="h-12 rounded-xl border border-slate-200 bg-slate-50 px-4 text-sm outline-none">
            <option value="">All Wallets</option>
            {(data?.providers || ['bKash', 'Nagad', 'Rocket']).map((item) => <option key={item} value={item}>{item}</option>)}
          </select>
          <select value={status} onChange={(event) => setStatus(event.target.value)} className="h-12 rounded-xl border border-slate-200 bg-slate-50 px-4 text-sm outline-none">
            <option value="">All Status</option>
            {(data?.statuses || []).map((item) => <option key={item} value={item}>{titleCase(item)}</option>)}
          </select>
        </div>

        {loading ? <LoadingBlock label="Loading wallet withdrawals..." /> : !data?.wallet_withdrawals ? (
          <ErrorBlock message="Wallet withdrawals are not available." />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full min-w-[1000px] text-left text-sm">
              <thead>
                <tr className="border-b border-slate-200 text-xs uppercase tracking-[0.16em] text-slate-400">
                  <th className="py-3">Transaction</th>
                  <th className="py-3">Customer</th>
                  <th className="py-3">Wallet</th>
                  <th className="py-3">Account</th>
                  <th className="py-3">Total</th>
                  <th className="py-3">Status</th>
                  <th className="py-3 text-right">Manage</th>
                </tr>
              </thead>
              <tbody>
                {data.wallet_withdrawals.data.map((item) => (
                  <tr key={item.id} className="border-b border-slate-100">
                    <td className="py-4">
                      <p className="font-medium text-slate-900">{item.transaction_id}</p>
                      <p className="text-xs text-slate-500">{formatDate(item.created_at)}</p>
                    </td>
                    <td className="py-4">
                      <p className="text-slate-900">{item.user?.name || 'App User'}</p>
                      <p className="text-xs text-slate-500">{item.email}</p>
                    </td>
                    <td className="py-4">
                      <p className="font-medium text-slate-900">{item.wallet_provider}</p>
                      <p className="text-xs text-slate-500">{item.wallet_number}</p>
                    </td>
                    <td className="py-4">
                      <p className="text-slate-900">{item.account_name || 'Not set'}</p>
                      <p className="text-xs text-slate-500">{item.contact_number || 'No contact'}</p>
                    </td>
                    <td className="py-4 font-medium text-slate-900">{formatMoney(item.total_amount)}</td>
                    <td className="py-4"><StatusBadge status={item.status} /></td>
                    <td className="py-4">
                      <div className="flex justify-end gap-2">
                        <button disabled={saving} onClick={() => quickStatus(item, 'successful')} className="rounded-xl border border-emerald-200 px-3 py-2 text-xs text-emerald-700 hover:bg-emerald-50">Approve</button>
                        <button disabled={saving} onClick={() => quickStatus(item, 'failed')} className="rounded-xl border border-red-200 px-3 py-2 text-xs text-red-700 hover:bg-red-50">Fail</button>
                        <button onClick={() => openEdit(item)} className="rounded-xl border border-slate-200 p-2 text-slate-600 hover:bg-slate-50"><Edit3 size={16} /></button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Panel>

      {editing && form ? (
        <WalletWithdrawalEditModal
          data={data}
          form={form}
          saving={saving}
          setForm={setForm}
          onClose={() => { setEditing(null); setForm(null); }}
          onSubmit={saveEdit}
        />
      ) : null}
    </div>
  );
}

function WalletWithdrawalEditModal({ data, form, saving, setForm, onClose, onSubmit }) {
  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-slate-950/45 p-3 sm:items-center">
      <form onSubmit={onSubmit} className="max-h-[92vh] w-full max-w-2xl overflow-y-auto rounded-[14px] border border-slate-200 bg-white p-5 shadow-sm">
        <div className="flex items-start justify-between gap-4">
          <div>
            <p className="text-xs uppercase tracking-[0.22em] text-red-600">Wallet Withdrawal</p>
            <h3 className="mt-2 text-xl font-medium text-slate-950">Edit Withdrawal Request</h3>
          </div>
          <button type="button" onClick={onClose} className="rounded-xl border border-slate-200 p-2 text-slate-500 hover:bg-slate-50"><X size={18} /></button>
        </div>
        <div className="mt-5 grid gap-4 md:grid-cols-2">
          <select value={form.wallet_provider} onChange={(event) => setForm({ ...form, wallet_provider: event.target.value })} className="h-12 rounded-xl border border-slate-200 bg-slate-50 px-4 text-sm outline-none">
            {(data?.providers || ['bKash', 'Nagad', 'Rocket']).map((item) => <option key={item} value={item}>{item}</option>)}
          </select>
          <Field label="Wallet Number" value={form.wallet_number} onChange={(wallet_number) => setForm({ ...form, wallet_number })} required />
          <Field label="Account Name" value={form.account_name} onChange={(account_name) => setForm({ ...form, account_name })} />
          <Field label="Contact Number" value={form.contact_number} onChange={(contact_number) => setForm({ ...form, contact_number })} />
          <Field label="Amount" type="number" value={form.amount} onChange={(amount) => setForm({ ...form, amount })} required />
          <Field label="Charge" type="number" value={form.charge} onChange={(charge) => setForm({ ...form, charge })} />
          <select value={form.status} onChange={(event) => setForm({ ...form, status: event.target.value })} className="h-12 rounded-xl border border-slate-200 bg-slate-50 px-4 text-sm outline-none">
            {(data?.statuses || []).map((item) => <option key={item} value={item}>{titleCase(item)}</option>)}
          </select>
        </div>
        <label className="mt-4 block">
          <span className="mb-2 block text-sm font-medium text-slate-700">Admin Note</span>
          <textarea value={form.admin_note} onChange={(event) => setForm({ ...form, admin_note: event.target.value })} rows="4" className="w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm outline-none" />
        </label>
        <div className="mt-5 flex justify-end gap-3">
          <button type="button" onClick={onClose} className="rounded-xl border border-slate-200 px-5 py-3 text-sm text-slate-600 hover:bg-slate-50">Cancel</button>
          <button disabled={saving} className="rounded-xl bg-red-600 px-5 py-3 text-sm font-medium text-white hover:bg-red-700 disabled:opacity-60">{saving ? 'Saving...' : 'Save Withdrawal'}</button>
        </div>
      </form>
    </div>
  );
}

function ChatSupportPage() {
  const [data, setData] = useState(null);
  const [active, setActive] = useState(null);
  const [chatOpen, setChatOpen] = useState(false);
  const [messages, setMessages] = useState([]);
  const [draft, setDraft] = useState('');
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState('');
  const [imageDraft, setImageDraft] = useState(null);
  const [imageEditor, setImageEditor] = useState(null);
  const [messageAlerts, setMessageAlerts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [sending, setSending] = useState(false);
  const [error, setError] = useState('');
  const lastMessageIdRef = useRef(null);
  const knownUserMessageIdsRef = useRef(new Set());
  const typingToneAtRef = useRef(0);
  const userTypingRef = useRef(false);

  const query = useMemo(() => ({ search, status }), [search, status]);

  function applyMessages(nextMessages, audible = false) {
    const latest = nextMessages[nextMessages.length - 1];
    const latestId = Number(latest?.id || 0);
    if (audible && latestId && latestId !== lastMessageIdRef.current && latest?.sender_type === 'user') {
      playChatTone('receive');
    }
    lastMessageIdRef.current = latestId || lastMessageIdRef.current;
    setMessages(nextMessages);
  }

  async function loadConversations(silent = false) {
    if (!silent) setLoading(true);
    try {
      const response = await api.get('/admin/chats', { params: query });
      processIncomingConversations(response.data?.conversations?.data || [], silent);
      setData(response.data);
    } catch (apiError) {
      setError(apiError.response?.data?.message || 'Could not load chat inbox.');
    } finally {
      if (!silent) setLoading(false);
    }
  }

  function latestConversationMessage(conversation) {
    return conversation?.messages?.[0] || null;
  }

  function processIncomingConversations(conversations, shouldAlert) {
    const incomingAlerts = [];

    conversations.forEach((conversation) => {
      [...(conversation.messages || [])].reverse().forEach((message) => {
        if (!message || message.sender_type !== 'user') return;

        const messageId = Number(message.id || 0);
        if (!messageId) return;

        if (!knownUserMessageIdsRef.current.has(messageId)) {
          knownUserMessageIdsRef.current.add(messageId);

          if (shouldAlert) {
            incomingAlerts.push({
              id: messageId,
              conversation,
              message,
            });
          }
        }
      });
    });

    if (!incomingAlerts.length) return;

    playChatTone('receive');
    incomingAlerts.forEach((alert) => notifyBrowserForChat(alert));
    setMessageAlerts((current) => [...current, ...incomingAlerts]);
  }

  function notifyBrowserForChat(alert) {
    if (!('Notification' in window) || Notification.permission !== 'granted') return;

    const userName = alert.conversation.user_name || 'App User';
    const body = alert.message.message || (hasChatImage(alert.message) ? 'Sent an image.' : 'Sent a new message.');
    const notification = new Notification(`New message from ${userName}`, {
      body,
      icon: '/favicon.ico',
      tag: `chat-message-${alert.id}`,
    });

    notification.onclick = () => {
      window.focus();
      openConversation(alert.conversation);
      setMessageAlerts((current) => current.filter((item) => item.id !== alert.id));
      notification.close();
    };
  }

  async function openConversation(conversation, silent = false) {
    try {
      unlockChatAudio();
      const response = await api.get(`/admin/chats/${conversation.id}`);
      setActive(response.data.conversation);
      setChatOpen(true);
      applyMessages(response.data.messages || [], false);
      if (!silent) await loadConversations(true);
    } catch (apiError) {
      setError(apiError.response?.data?.message || 'Could not open conversation.');
    }
  }

  useEffect(() => {
    loadConversations();
  }, [query]);

  useEffect(() => {
    if ('Notification' in window && Notification.permission === 'default') {
      Promise.resolve(Notification.requestPermission()).catch(() => {});
    }
  }, []);

  useEffect(() => {
    const timer = window.setInterval(async () => {
      await loadConversations(true);
      if (active?.id && chatOpen) {
        const response = await api.get(`/admin/chats/${active.id}`);
        if (response.data.conversation?.user_typing && !userTypingRef.current) {
          playChatTone('typing');
        }
        userTypingRef.current = response.data.conversation?.user_typing === true;
        setActive(response.data.conversation);
        applyMessages(response.data.messages || [], true);
      }
    }, 3000);

    return () => window.clearInterval(timer);
  }, [active?.id, chatOpen, query]);

  async function sendMessage(event) {
    event.preventDefault();
    const message = draft.trim();
    if ((!message && !imageDraft) || !active?.id) return;

    setSending(true);
    try {
      const payload = imageDraft ? new FormData() : { message };
      if (imageDraft) {
        payload.append('message', message);
        payload.append('image', imageDraft.file, imageDraft.file.name);
      }
      const response = await api.post(`/admin/chats/${active.id}/messages`, payload);
      playChatTone('send');
      setDraft('');
      setImageDraft(null);
      applyMessages([...messages, response.data.chat_message], false);
      setActive(response.data.conversation);
      await loadConversations(true);
    } catch (apiError) {
      setError(apiError.response?.data?.message || 'Could not send message.');
    } finally {
      setSending(false);
    }
  }

  async function sendTyping() {
    if (!active?.id) return;
    unlockChatAudio();
    const now = Date.now();
    if (now - typingToneAtRef.current > 900) {
      typingToneAtRef.current = now;
      playChatTone('typing');
    }
    try {
      await api.post(`/admin/chats/${active.id}/typing`);
    } catch (_) {
      // Typing is ephemeral; ignore failure.
    }
  }

  function openImageEditor(file) {
    if (!file || !file.type.startsWith('image/')) return;
    const reader = new FileReader();
    reader.onload = () => setImageEditor({ name: file.name, src: reader.result });
    reader.readAsDataURL(file);
  }

  async function changeStatus(nextStatus) {
    if (!active?.id) return;
    try {
      const response = await api.put(`/admin/chats/${active.id}`, { status: nextStatus });
      setActive(response.data.conversation);
      await loadConversations(true);
    } catch (apiError) {
      setError(apiError.response?.data?.message || 'Could not update conversation.');
    }
  }

  async function toggleChatBan() {
    if (!active?.id) return;
    try {
      const response = await api.put(`/admin/chats/${active.id}`, { chat_banned: !active.chat_banned });
      setActive(response.data.conversation);
      await loadConversations(true);
    } catch (apiError) {
      setError(apiError.response?.data?.message || 'Could not update chat access.');
    }
  }

  return (
    <div className="space-y-6">
      <div className="overflow-hidden rounded-[16px] border border-slate-200 bg-slate-950 p-5 text-white shadow-sm">
        <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
          <div>
            <p className="text-xs uppercase tracking-[0.22em] text-red-300">Support Desk</p>
            <h2 className="mt-2 text-2xl font-medium">Live Chat Command Center</h2>
            <p className="mt-2 max-w-2xl text-sm leading-6 text-slate-300">Typing status, seen/unseen state, unread inbox and chat tones are ready for fast customer support.</p>
          </div>
          <div className="rounded-xl border border-white/10 bg-white/10 px-4 py-3 text-sm text-slate-200">
            <span className="mr-2 inline-block h-2 w-2 rounded-full bg-emerald-400" />
            Support online
          </div>
        </div>
      </div>

      {error ? <div className="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">{error}</div> : null}

      <div className="min-h-[620px]">
        <Panel title="Conversations">
          <div className="mb-4 space-y-3">
            <div className="flex items-center gap-2 rounded-xl border border-slate-200 bg-slate-50 px-4">
              <Search size={18} className="text-slate-400" />
              <input value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Search user, email or phone" className="h-12 w-full bg-transparent text-sm outline-none" />
            </div>
            <select value={status} onChange={(event) => setStatus(event.target.value)} className="h-12 w-full rounded-xl border border-slate-200 bg-slate-50 px-4 text-sm outline-none">
              <option value="">All Status</option>
              {(data?.statuses || []).map((item) => <option key={item} value={item}>{titleCase(item)}</option>)}
            </select>
          </div>

          {loading ? <LoadingBlock label="Loading chat inbox..." /> : !data?.conversations?.data?.length ? (
            <p className="rounded-xl border border-slate-200 bg-slate-50 p-5 text-sm text-slate-500">No conversations yet.</p>
          ) : (
            <div className="max-h-[560px] space-y-2 overflow-y-auto pr-1">
              {data.conversations.data.map((conversation) => {
                const selected = chatOpen && active?.id === conversation.id;
                const unread = conversation.unread_for_admin || 0;
                const isUnread = unread > 0;
                const latest = conversation.messages?.[0]?.message || 'No messages yet';
                return (
                  <button key={conversation.id} onClick={() => openConversation(conversation)} className={`w-full rounded-[12px] border p-4 text-left transition ${isUnread ? 'border-red-200 bg-red-50 shadow-sm' : selected ? 'border-slate-300 bg-slate-50 shadow-sm' : 'border-slate-200 bg-white hover:border-slate-300 hover:bg-slate-50'}`}>
                    <div className="flex items-start justify-between gap-3">
                      <div className="flex min-w-0 items-center gap-3">
                        <div className={`flex h-11 w-11 shrink-0 items-center justify-center rounded-xl text-sm font-medium ${selected ? 'bg-red-600 text-white' : 'bg-slate-100 text-slate-700'}`}>
                          {(conversation.user_name || 'U').slice(0, 1).toUpperCase()}
                        </div>
                        <div className="min-w-0">
                          <p className="truncate font-medium text-slate-950">{conversation.user_name || 'App User'}</p>
                          <p className="truncate text-xs text-slate-500">{conversation.email}</p>
                        </div>
                      </div>
                      {isUnread ? <span className="rounded-full bg-red-600 px-2.5 py-1 text-xs font-medium text-white">{unread} new</span> : <span className="rounded-full border border-emerald-200 bg-emerald-50 px-2.5 py-1 text-xs font-medium text-emerald-700">Seen</span>}
                    </div>
                    <p className={`mt-3 line-clamp-2 text-sm leading-5 ${isUnread ? 'font-medium text-slate-950' : 'text-slate-500'}`}>{latest}</p>
                    <div className="mt-3 flex items-center justify-between gap-3">
                      <StatusBadge status={conversation.status} />
                      <span className={`text-xs font-medium ${isUnread ? 'text-red-600' : 'text-slate-400'}`}>
                        {isUnread ? 'Unseen message' : 'No unseen message'}
                      </span>
                    </div>
                    {conversation.user_typing ? <div className="mt-3"><TypingDots label="Typing" compact /></div> : null}
                  </button>
                );
              })}
            </div>
          )}
        </Panel>

        {chatOpen && active ? (
          <div className="fixed inset-0 z-50 flex items-end justify-center bg-slate-950/55 p-3 sm:items-center">
            <div className="flex max-h-[92vh] min-h-[640px] w-full max-w-4xl flex-col overflow-hidden rounded-[16px] border border-slate-200 bg-white shadow-2xl">
              <div className="flex flex-wrap items-center justify-between gap-3 border-b border-slate-100 bg-slate-50 px-5 py-4">
                <div>
                  <h3 className="text-lg font-medium text-slate-950">{active.user_name || 'App User'}</h3>
                  <p className="text-sm text-slate-500">{active.email} {active.user_phone ? `· ${active.user_phone}` : ''}</p>
                  {active.user_typing ? <div className="mt-1"><TypingDots label="User is typing" compact /></div> : null}
                </div>
                <div className="flex flex-wrap items-center gap-2">
                  {active.chat_banned ? <StatusBadge status="chat banned" /> : null}
                  <button onClick={toggleChatBan} className="h-11 rounded-xl border border-amber-200 bg-white px-4 text-sm text-amber-700 hover:bg-amber-50">
                    {active.chat_banned ? 'Chat Unban' : 'Chat Ban'}
                  </button>
                  <select value={active.status} onChange={(event) => changeStatus(event.target.value)} className="h-11 rounded-xl border border-slate-200 bg-slate-50 px-4 text-sm outline-none">
                    {(data?.statuses || ['open', 'pending', 'resolved', 'closed']).map((item) => <option key={item} value={item}>{titleCase(item)}</option>)}
                  </select>
                </div>
                <button onClick={() => setChatOpen(false)} className="rounded-xl border border-slate-200 bg-white p-2 text-slate-500 hover:bg-slate-100">
                  <X size={18} />
                </button>
              </div>

              <div className="flex-1 space-y-3 overflow-y-auto bg-[#f8fafc] px-5 py-5">
                {messages.map((message) => {
                  const mine = message.sender_type === 'admin';
                  return (
                    <div key={message.id} className={`flex ${mine ? 'justify-end' : 'justify-start'}`}>
                      <div className={`max-w-[78%] rounded-[12px] border px-4 py-3 shadow-sm ${mine ? 'border-red-600 bg-red-600 text-white' : 'border-slate-200 bg-white text-slate-800'}`}>
                        {hasChatImage(message) ? (
                          <img src={chatImageSrc(message)} alt={message.attachment_name || 'Chat attachment'} className="mb-3 max-h-72 rounded-xl border border-white/20 object-cover" />
                        ) : null}
                        {message.message ? <p className="whitespace-pre-wrap text-sm leading-6">{message.message}</p> : null}
                        <p className={`mt-2 text-[11px] ${mine ? 'text-white/75' : 'text-slate-400'}`}>
                          {formatDate(message.created_at)} {mine ? `· ${message.seen_at ? 'Seen ' + formatDate(message.seen_at) : 'Delivered'}` : ''}
                        </p>
                      </div>
                    </div>
                  );
                })}
                {active.user_typing ? (
                  <div className="flex justify-start">
                    <div className="rounded-[12px] border border-slate-200 bg-white px-4 py-3 shadow-sm">
                      <TypingDots label="User is typing" />
                    </div>
                  </div>
                ) : null}
              </div>

              <form onSubmit={sendMessage} className="flex gap-3 border-t border-slate-100 bg-white p-4">
                <label className="flex h-12 w-12 cursor-pointer items-center justify-center rounded-xl border border-slate-200 bg-slate-50 text-slate-500 hover:bg-slate-100">
                  <input type="file" accept="image/*" className="hidden" onChange={(event) => openImageEditor(event.target.files?.[0])} />
                  <span className="text-lg">＋</span>
                </label>
                <div className="flex-1">
                  {imageDraft ? (
                    <div className="mb-2 flex items-center justify-between rounded-xl border border-red-100 bg-red-50 px-3 py-2 text-xs text-red-700">
                      <span className="truncate">Image ready: {imageDraft.file.name}</span>
                      <button type="button" onClick={() => setImageDraft(null)} className="ml-3 font-medium">Remove</button>
                    </div>
                  ) : null}
                  <input value={draft} onChange={(event) => { setDraft(event.target.value); sendTyping(); }} placeholder="Write a reply..." className="h-12 w-full rounded-xl border border-slate-200 bg-slate-50 px-4 text-sm outline-none focus:border-red-300 focus:bg-white" />
                </div>
                <button disabled={sending || (!draft.trim() && !imageDraft)} className="rounded-xl bg-red-600 px-5 text-sm font-medium text-white hover:bg-red-700 disabled:opacity-60">{sending ? 'Sending...' : 'Send'}</button>
              </form>
            </div>
          </div>
        ) : null}
        {imageEditor ? (
          <ChatImageEditor
            image={imageEditor}
            onClose={() => setImageEditor(null)}
            onSave={(file) => {
              setImageDraft({ file });
              setImageEditor(null);
            }}
          />
        ) : null}
        {messageAlerts.length ? (
          <ChatMessageAlert
            alert={messageAlerts[0]}
            onClose={() => setMessageAlerts((current) => current.slice(1))}
            onOpen={() => {
              const alert = messageAlerts[0];
              setMessageAlerts((current) => current.slice(1));
              openConversation(alert.conversation);
            }}
          />
        ) : null}
      </div>
    </div>
  );
}

function ChatMessageAlert({ alert, onClose, onOpen }) {
  const userName = alert.conversation.user_name || 'App User';
  const messageText = alert.message.message || (hasChatImage(alert.message) ? 'Sent an image.' : 'Sent a new message.');

  return (
    <div className="fixed inset-0 z-[70] flex items-end justify-center bg-slate-950/45 p-3 sm:items-center">
      <div className="w-full max-w-md overflow-hidden rounded-[14px] border border-slate-200 bg-white shadow-2xl">
        <div className="border-b border-slate-100 bg-slate-50 px-5 py-4">
          <div className="flex items-start justify-between gap-3">
            <div className="flex items-center gap-3">
              <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-red-600 text-base font-medium text-white">
                {userName.slice(0, 1).toUpperCase()}
              </div>
              <div>
                <p className="text-xs uppercase tracking-[0.2em] text-red-600">New Chat Message</p>
                <h3 className="mt-1 text-lg font-medium text-slate-950">{userName}</h3>
              </div>
            </div>
            <button type="button" onClick={onClose} className="rounded-xl border border-slate-200 bg-white p-2 text-slate-500 hover:bg-slate-100">
              <X size={18} />
            </button>
          </div>
        </div>
        <div className="px-5 py-5">
          <p className="text-sm text-slate-500">{alert.conversation.email}</p>
          <div className="mt-4 rounded-xl border border-slate-200 bg-slate-50 p-4">
            <p className="line-clamp-4 text-sm leading-6 text-slate-800">{messageText}</p>
          </div>
          <div className="mt-5 flex justify-end gap-3">
            <button type="button" onClick={onClose} className="rounded-xl border border-slate-200 px-4 py-3 text-sm text-slate-600 hover:bg-slate-50">Later</button>
            <button type="button" onClick={onOpen} className="rounded-xl bg-red-600 px-5 py-3 text-sm font-medium text-white hover:bg-red-700">Open Chat</button>
          </div>
        </div>
      </div>
    </div>
  );
}

function TypingDots({ label = 'Typing', compact = false }) {
  return (
    <div className={`flex items-center gap-2 ${compact ? 'text-xs' : 'text-sm'} font-medium text-red-600`}>
      <span>{label}</span>
      <span className="flex items-center gap-1">
        {[0, 1, 2].map((item) => (
          <span
            key={item}
            className="h-1.5 w-1.5 animate-bounce rounded-full bg-red-600"
            style={{ animationDelay: `${item * 120}ms` }}
          />
        ))}
      </span>
    </div>
  );
}

function ChatImageEditor({ image, onClose, onSave }) {
  const canvasRef = useRef(null);
  const imageRef = useRef(null);
  const drawingRef = useRef(false);
  const [scale, setScale] = useState(1);
  const [brushColor, setBrushColor] = useState('#ef4444');
  const [brushSize, setBrushSize] = useState(5);

  useEffect(() => {
    const img = new Image();
    img.onload = () => {
      imageRef.current = img;
      drawCanvas();
    };
    img.src = image.src;
  }, [image.src]);

  useEffect(() => {
    drawCanvas();
  }, [scale]);

  function drawCanvas() {
    const canvas = canvasRef.current;
    const img = imageRef.current;
    if (!canvas || !img) return;
    const context = canvas.getContext('2d');
    context.clearRect(0, 0, canvas.width, canvas.height);
    context.fillStyle = '#f8fafc';
    context.fillRect(0, 0, canvas.width, canvas.height);
    const ratio = Math.min(canvas.width / img.width, canvas.height / img.height) * scale;
    const width = img.width * ratio;
    const height = img.height * ratio;
    context.drawImage(img, (canvas.width - width) / 2, (canvas.height - height) / 2, width, height);
  }

  function point(event) {
    const rect = canvasRef.current.getBoundingClientRect();
    return {
      x: (event.clientX - rect.left) * (canvasRef.current.width / rect.width),
      y: (event.clientY - rect.top) * (canvasRef.current.height / rect.height),
    };
  }

  function startBrush(event) {
    drawingRef.current = true;
    const context = canvasRef.current.getContext('2d');
    const start = point(event);
    context.beginPath();
    context.moveTo(start.x, start.y);
  }

  function moveBrush(event) {
    if (!drawingRef.current) return;
    const context = canvasRef.current.getContext('2d');
    const next = point(event);
    context.lineTo(next.x, next.y);
    context.strokeStyle = brushColor;
    context.lineWidth = brushSize;
    context.lineCap = 'round';
    context.lineJoin = 'round';
    context.stroke();
  }

  function save() {
    canvasRef.current.toBlob((blob) => {
      if (!blob) return;
      onSave(new File([blob], `edited-${image.name || 'chat-image'}.png`, { type: 'image/png' }));
    }, 'image/png', 0.92);
  }

  return (
    <div className="fixed inset-0 z-[60] flex items-center justify-center bg-slate-950/70 p-3">
      <div className="w-full max-w-3xl rounded-[16px] border border-slate-200 bg-white p-5 shadow-2xl">
        <div className="flex items-center justify-between gap-4">
          <div>
            <p className="text-xs uppercase tracking-[0.22em] text-red-600">Image Editor</p>
            <h3 className="mt-1 text-xl font-medium text-slate-950">Crop & brush before send</h3>
          </div>
          <button type="button" onClick={onClose} className="rounded-xl border border-slate-200 p-2 text-slate-500 hover:bg-slate-50"><X size={18} /></button>
        </div>
        <div className="mt-5 overflow-hidden rounded-xl border border-slate-200 bg-slate-100">
          <canvas
            ref={canvasRef}
            width="900"
            height="560"
            onPointerDown={startBrush}
            onPointerMove={moveBrush}
            onPointerUp={() => { drawingRef.current = false; }}
            onPointerLeave={() => { drawingRef.current = false; }}
            className="h-[52vh] max-h-[560px] w-full touch-none object-contain"
          />
        </div>
        <div className="mt-4 grid gap-3 md:grid-cols-[1fr_180px_160px]">
          <label className="rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm text-slate-600">
            Crop zoom
            <input type="range" min="1" max="2.4" step="0.05" value={scale} onChange={(event) => setScale(Number(event.target.value))} className="mt-2 w-full" />
          </label>
          <label className="rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm text-slate-600">
            Brush color
            <input type="color" value={brushColor} onChange={(event) => setBrushColor(event.target.value)} className="mt-2 h-8 w-full" />
          </label>
          <label className="rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm text-slate-600">
            Brush size
            <input type="range" min="2" max="18" value={brushSize} onChange={(event) => setBrushSize(Number(event.target.value))} className="mt-2 w-full" />
          </label>
        </div>
        <div className="mt-5 flex justify-end gap-3">
          <button type="button" onClick={drawCanvas} className="rounded-xl border border-slate-200 px-5 py-3 text-sm text-slate-600 hover:bg-slate-50">Reset Brush</button>
          <button type="button" onClick={onClose} className="rounded-xl border border-slate-200 px-5 py-3 text-sm text-slate-600 hover:bg-slate-50">Cancel</button>
          <button type="button" onClick={save} className="rounded-xl bg-red-600 px-5 py-3 text-sm font-medium text-white hover:bg-red-700">Use Image</button>
        </div>
      </div>
    </div>
  );
}

function UsersPage() {
  const [formOpen, setFormOpen] = useState(false);
  const [editingUser, setEditingUser] = useState(null);
  const [usersData, setUsersData] = useState(null);
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState('');
  const [loading, setLoading] = useState(true);
  const [notice, setNotice] = useState('');

  const query = useMemo(() => ({ search, status }), [search, status]);

  async function loadUsers() {
    setLoading(true);
    try {
      const { data } = await api.get('/admin/users', { params: query });
      setUsersData(data);
    } catch (apiError) {
      setNotice(apiError.response?.data?.message || 'Could not load users.');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadUsers();
  }, [query]);

  function openCreate() {
    setEditingUser(null);
    setFormOpen(true);
  }

  function openEdit(user) {
    setEditingUser(user);
    setFormOpen(true);
  }

  async function removeUser(user) {
    if (!window.confirm(`Delete ${user.name}? This action cannot be undone.`)) return;
    await api.delete(`/admin/users/${user.id}`);
    setNotice('User deleted successfully.');
    loadUsers();
  }

  async function updateUserAccess(user, updates) {
    const payload = {
      ...user,
      chat_banned: Boolean(user.chat_banned_at),
      ...updates,
      password: '',
      password_confirmation: '',
    };
    delete payload.created_at;
    delete payload.updated_at;
    delete payload.email_verified_at;
    delete payload.chat_banned_at;
    await api.put(`/admin/users/${user.id}`, payload);
    setNotice('User access updated successfully.');
    loadUsers();
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-3 rounded-[14px] border border-slate-200 bg-white p-4 shadow-sm md:flex-row md:items-center md:justify-between">
        <div>
          <h2 className="text-lg font-medium text-slate-950">User Management</h2>
          <p className="mt-1 text-sm text-slate-500">Create, edit, filter and safely remove platform users.</p>
        </div>
        <button onClick={openCreate} className="inline-flex items-center justify-center gap-2 rounded-xl bg-red-600 px-4 py-3 text-sm font-medium text-white hover:bg-red-700">
          <Plus size={17} /> Add User
        </button>
      </div>

      {notice ? <div className="rounded-xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-700">{notice}</div> : null}

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-5">
        {usersData ? Object.entries(usersData.stats).map(([key, value]) => (
          <div key={key} className="rounded-xl border border-slate-200 bg-white p-4">
            <p className="text-xs uppercase tracking-[0.18em] text-slate-400">{key.replace('_', ' ')}</p>
            <p className="mt-2 text-2xl font-medium">{value}</p>
          </div>
        )) : null}
      </div>

      <Panel title="All Users">
        <div className="mb-4 grid gap-3 md:grid-cols-[1fr_180px]">
          <div className="flex items-center gap-2 rounded-xl border border-slate-200 bg-slate-50 px-4">
            <Search size={18} className="text-slate-400" />
            <input value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Search by name, email or phone" className="h-12 w-full bg-transparent text-sm outline-none" />
          </div>
          <select value={status} onChange={(event) => setStatus(event.target.value)} className="h-12 rounded-xl border border-slate-200 bg-slate-50 px-4 text-sm outline-none">
            <option value="">All Status</option>
            <option value="active">Active</option>
            <option value="pending">Pending</option>
            <option value="inactive">Inactive</option>
            <option value="banned">Banned</option>
          </select>
        </div>

        {loading ? <LoadingBlock label="Loading users..." /> : !usersData?.users ? (
          <ErrorBlock message="Users are not available." />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full min-w-[880px] text-left text-sm">
              <thead>
                <tr className="border-b border-slate-200 text-xs uppercase tracking-[0.16em] text-slate-400">
                  <th className="py-3">User</th>
                  <th className="py-3">Phone</th>
                  <th className="py-3">Address</th>
                  <th className="py-3">Balance</th>
                  <th className="py-3">Status</th>
                  <th className="py-3 text-right">Actions</th>
                </tr>
              </thead>
              <tbody>
                {usersData.users.data.map((user) => (
                  <tr key={user.id} className="border-b border-slate-100">
                    <td className="py-4">
                      <p className="font-medium text-slate-900">{user.name}</p>
                      <p className="text-xs text-slate-500">{user.email}</p>
                    </td>
                    <td className="py-4 text-slate-600">{user.phone || '—'}</td>
                    <td className="max-w-xs truncate py-4 text-slate-600">{user.address || '—'}</td>
                    <td className="py-4 font-medium text-slate-900">{formatMoney(user.balance)}</td>
                    <td className="py-4"><StatusBadge status={user.status} /></td>
                    <td className="py-4">
                      <div className="flex justify-end gap-2">
                        <button onClick={() => updateUserAccess(user, { status: user.status === 'banned' ? 'active' : 'banned' })} className="rounded-xl border border-amber-200 px-3 py-2 text-xs text-amber-700 hover:bg-amber-50">
                          {user.status === 'banned' ? 'Unban' : 'Ban'}
                        </button>
                        <button onClick={() => updateUserAccess(user, { chat_banned: !Boolean(user.chat_banned_at) })} className="rounded-xl border border-slate-200 px-3 py-2 text-xs text-slate-600 hover:bg-slate-50">
                          {user.chat_banned_at ? 'Chat Unban' : 'Chat Ban'}
                        </button>
                        <button onClick={() => openEdit(user)} className="rounded-xl border border-slate-200 p-2 text-slate-600 hover:bg-slate-50"><Edit3 size={16} /></button>
                        <button onClick={() => removeUser(user)} className="rounded-xl border border-red-200 p-2 text-red-600 hover:bg-red-50"><Trash2 size={16} /></button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Panel>
      {formOpen ? (
        <UserFormModal user={editingUser} onBack={() => setFormOpen(false)} onSaved={(message) => {
          setNotice(message);
          setFormOpen(false);
          loadUsers();
        }} />
      ) : null}
    </div>
  );
}

function UserFormModal({ user, onBack, onSaved }) {
  const [form, setForm] = useState(() => user ? { ...emptyForm, ...user, chat_banned: Boolean(user.chat_banned_at), password: '', password_confirmation: '' } : emptyForm);
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);

  async function submit(event) {
    event.preventDefault();
    setSaving(true);
    setError('');

    const payload = { ...form };
    if (!payload.password) {
      delete payload.password;
      delete payload.password_confirmation;
    }

    try {
      const response = user
        ? await api.put(`/admin/users/${user.id}`, payload)
        : await api.post('/admin/users', payload);
      onSaved(response.data.message);
    } catch (apiError) {
      const errors = apiError.response?.data?.errors;
      setError(errors ? Object.values(errors).flat()[0] : (apiError.response?.data?.message || 'Could not save user.'));
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-slate-950/45 p-3 sm:items-center">
      <form onSubmit={submit} className="max-h-[92vh] w-full max-w-4xl overflow-y-auto rounded-[14px] border border-slate-200 bg-white p-5 shadow-sm">
        <div className="flex items-start justify-between gap-4">
          <div>
            <p className="text-xs uppercase tracking-[0.22em] text-red-600">User Management</p>
            <h2 className="mt-2 text-xl font-medium text-slate-950">{user ? 'Edit User' : 'Create User'}</h2>
            <p className="mt-1 text-sm text-slate-500">Keep profile, wallet balance and account status updated.</p>
          </div>
          <button type="button" onClick={onBack} className="rounded-xl border border-slate-200 p-2 text-slate-500 hover:bg-slate-50">
            <X size={18} />
          </button>
        </div>

        {error ? <div className="mt-5 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">{error}</div> : null}

        <div className="mt-5 rounded-[14px] border border-slate-200 bg-white p-5">
          <h3 className="mb-4 text-base font-medium text-slate-950">Account Information</h3>
          <div className="grid gap-4 md:grid-cols-2">
            <Field label="Full Name" value={form.name || ''} onChange={(name) => setForm({ ...form, name })} required />
            <Field label="Email" type="email" value={form.email || ''} onChange={(email) => setForm({ ...form, email })} required />
            <Field label="Phone" value={form.phone || ''} onChange={(phone) => setForm({ ...form, phone })} />
            <Field label="Address" value={form.address || ''} onChange={(address) => setForm({ ...form, address })} />
            <Field label="First Name" value={form.first_name || ''} onChange={(first_name) => setForm({ ...form, first_name })} />
            <Field label="Last Name" value={form.last_name || ''} onChange={(last_name) => setForm({ ...form, last_name })} />
            <Field label="Country" value={form.country_name || ''} onChange={(country_name) => setForm({ ...form, country_name })} />
            <Field label="Country Code" value={form.country_code || ''} onChange={(country_code) => setForm({ ...form, country_code })} />
          </div>
        </div>

        <div className="mt-5 rounded-[14px] border border-slate-200 bg-white p-5">
          <h3 className="mb-4 text-base font-medium text-slate-950">Wallet, Security & Status</h3>
          <div className="grid gap-4 md:grid-cols-2">
            <Field label="Wallet Balance" type="number" value={form.balance?.toString() || '0'} onChange={(balance) => setForm({ ...form, balance })} />
            <Field label={user ? 'New Password (optional)' : 'Password'} type="password" value={form.password || ''} onChange={(password) => setForm({ ...form, password })} required={!user} />
            <Field label="Confirm Password" type="password" value={form.password_confirmation || ''} onChange={(password_confirmation) => setForm({ ...form, password_confirmation })} required={!user} />
            <label className="block">
              <span className="mb-2 block text-sm font-medium text-slate-700">Status</span>
              <select value={form.status} onChange={(event) => setForm({ ...form, status: event.target.value })} className="h-12 w-full rounded-xl border border-slate-200 bg-slate-50 px-4 text-sm outline-none focus:border-red-400">
                <option value="active">Active</option>
                <option value="pending">Pending</option>
                <option value="inactive">Inactive</option>
                <option value="banned">Banned</option>
              </select>
            </label>
            <label className="flex items-center gap-3 rounded-xl border border-slate-200 bg-slate-50 px-4 py-3">
              <input type="checkbox" checked={Boolean(form.is_admin)} onChange={(event) => setForm({ ...form, is_admin: event.target.checked })} />
              <span className="text-sm text-slate-700">Allow admin access</span>
            </label>
            <label className="flex items-center gap-3 rounded-xl border border-slate-200 bg-slate-50 px-4 py-3">
              <input type="checkbox" checked={Boolean(form.chat_banned)} onChange={(event) => setForm({ ...form, chat_banned: event.target.checked })} />
              <span className="text-sm text-slate-700">Ban from live chat only</span>
            </label>
            <Field label="Ban Reason" value={form.ban_reason || ''} onChange={(ban_reason) => setForm({ ...form, ban_reason })} />
          </div>
        </div>

        <div className="mt-5 flex flex-col-reverse gap-3 sm:flex-row sm:justify-end">
          <button type="button" onClick={onBack} className="rounded-xl border border-slate-200 px-5 py-3 text-sm text-slate-600 hover:bg-slate-50">
            Cancel
          </button>
          <button disabled={saving} className="rounded-xl bg-red-600 px-6 py-3 text-sm font-medium text-white hover:bg-red-700 disabled:opacity-60">
            {saving ? 'Saving...' : 'Save User'}
          </button>
        </div>
      </form>
    </div>
  );
}

function UserForm({ user, onBack, onSaved }) {
  const [form, setForm] = useState(() => user ? { ...emptyForm, ...user, password: '', password_confirmation: '' } : emptyForm);
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);

  async function submit(event) {
    event.preventDefault();
    setSaving(true);
    setError('');

    const payload = { ...form };
    if (!payload.password) {
      delete payload.password;
      delete payload.password_confirmation;
    }

    try {
      const response = user
        ? await api.put(`/admin/users/${user.id}`, payload)
        : await api.post('/admin/users', payload);
      onSaved(response.data.message);
    } catch (apiError) {
      const errors = apiError.response?.data?.errors;
      setError(errors ? Object.values(errors).flat()[0] : (apiError.response?.data?.message || 'Could not save user.'));
    } finally {
      setSaving(false);
    }
  }

  return (
    <form onSubmit={submit} className="space-y-6">
      <div className="rounded-[14px] border border-slate-200 bg-white p-5 shadow-sm">
        <button type="button" onClick={onBack} className="text-sm text-slate-500 hover:text-slate-950">← Back to users</button>
        <h2 className="mt-4 text-xl font-medium">{user ? 'Edit User' : 'Create User'}</h2>
        <p className="mt-1 text-sm text-slate-500">Keep user profile, address and account status updated.</p>
      </div>

      {error ? <div className="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">{error}</div> : null}

      <Panel title="Account Information">
        <div className="grid gap-4 md:grid-cols-2">
          <Field label="Full Name" value={form.name || ''} onChange={(name) => setForm({ ...form, name })} required />
          <Field label="Email" type="email" value={form.email || ''} onChange={(email) => setForm({ ...form, email })} required />
          <Field label="Phone" value={form.phone || ''} onChange={(phone) => setForm({ ...form, phone })} />
          <Field label="Address" value={form.address || ''} onChange={(address) => setForm({ ...form, address })} />
          <Field label="First Name" value={form.first_name || ''} onChange={(first_name) => setForm({ ...form, first_name })} />
          <Field label="Last Name" value={form.last_name || ''} onChange={(last_name) => setForm({ ...form, last_name })} />
          <Field label="Country" value={form.country_name || ''} onChange={(country_name) => setForm({ ...form, country_name })} />
          <Field label="Country Code" value={form.country_code || ''} onChange={(country_code) => setForm({ ...form, country_code })} />
        </div>
      </Panel>

      <Panel title="Security & Status">
        <div className="grid gap-4 md:grid-cols-2">
          <Field label={user ? 'New Password (optional)' : 'Password'} type="password" value={form.password || ''} onChange={(password) => setForm({ ...form, password })} required={!user} />
          <Field label="Confirm Password" type="password" value={form.password_confirmation || ''} onChange={(password_confirmation) => setForm({ ...form, password_confirmation })} required={!user} />
          <label className="block">
            <span className="mb-2 block text-sm font-medium text-slate-700">Status</span>
            <select value={form.status} onChange={(event) => setForm({ ...form, status: event.target.value })} className="h-12 w-full rounded-xl border border-slate-200 bg-slate-50 px-4 text-sm outline-none focus:border-red-400">
              <option value="active">Active</option>
              <option value="pending">Pending</option>
              <option value="inactive">Inactive</option>
            </select>
          </label>
          <label className="flex items-center gap-3 rounded-xl border border-slate-200 bg-slate-50 px-4 py-3">
            <input type="checkbox" checked={Boolean(form.is_admin)} onChange={(event) => setForm({ ...form, is_admin: event.target.checked })} />
            <span className="text-sm text-slate-700">Allow admin access</span>
          </label>
        </div>
      </Panel>

      <button disabled={saving} className="rounded-xl bg-red-600 px-6 py-3 text-sm font-medium text-white hover:bg-red-700 disabled:opacity-60">
        {saving ? 'Saving...' : 'Save User'}
      </button>
    </form>
  );
}

function NotificationsPage() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [sending, setSending] = useState(false);
  const [error, setError] = useState('');
  const [notice, setNotice] = useState('');
  const [form, setForm] = useState({
    audience: 'all',
    user_id: '',
    title: '',
    body: '',
    action_type: 'none',
    action_value: '',
  });

  useEffect(() => {
    load();
  }, []);

  async function load() {
    setLoading(true);
    setError('');
    try {
      const response = await api.get('/admin/notifications');
      setData(response.data);
    } catch (apiError) {
      setError(apiError.response?.data?.message || 'Could not load notification dashboard.');
    } finally {
      setLoading(false);
    }
  }

  async function send(event) {
    event.preventDefault();
    setSending(true);
    setError('');
    setNotice('');
    try {
      const response = await api.post('/admin/notifications/send', form);
      const result = response.data.result || {};
      setNotice(`${response.data.message} Success: ${result.success || 0}, Failed: ${result.failed || 0}, Devices: ${result.targeted_devices || 0}.`);
      setForm({ ...form, title: '', body: '' });
      await load();
    } catch (apiError) {
      const errors = apiError.response?.data?.errors;
      setError(errors ? Object.values(errors).flat()[0] : (apiError.response?.data?.message || 'Could not send notification.'));
    } finally {
      setSending(false);
    }
  }

  const users = data?.users || [];

  return (
    <div className="space-y-5">
      <div className="rounded-[14px] border border-slate-200 bg-white p-5 shadow-sm">
        <div className="flex items-start gap-4">
          <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-red-50 text-red-600">
            <Bell size={22} />
          </div>
          <div>
            <p className="text-xs uppercase tracking-[0.2em] text-red-600">Firebase Cloud Messaging</p>
            <h2 className="mt-2 text-2xl font-medium text-slate-950">Push Notifications</h2>
            <p className="mt-1 text-sm text-slate-500">Send professional realtime notifications to all app users or a selected user device group.</p>
          </div>
        </div>
      </div>

      {data?.stats ? (
        <div className="grid gap-4 md:grid-cols-3">
          {[
            ['Active Devices', data.stats.active_devices],
            ['Android Devices', data.stats.android_devices],
            ['Users With Devices', data.stats.users_with_devices],
          ].map(([label, value]) => (
            <div key={label} className="rounded-[12px] border border-slate-200 bg-white p-4 shadow-sm">
              <p className="text-sm text-slate-500">{label}</p>
              <p className="mt-2 text-2xl font-medium text-slate-950">{value}</p>
            </div>
          ))}
        </div>
      ) : null}

      {notice ? <div className="rounded-xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-700">{notice}</div> : null}
      {error ? <ErrorBlock message={error} /> : null}

      {loading ? <LoadingBlock label="Loading notification tools..." /> : (
        <form onSubmit={send} className="grid gap-5 lg:grid-cols-[1fr_360px]">
          <Panel title="Compose Notification">
            <div className="space-y-4">
              <SelectField label="Audience" value={form.audience} onChange={(audience) => setForm({ ...form, audience })} options={['all', 'user']} />
              {form.audience === 'user' ? (
                <label className="block">
                  <span className="mb-2 block text-sm font-medium text-slate-700">Select User</span>
                  <select value={form.user_id} onChange={(event) => setForm({ ...form, user_id: event.target.value })} className="h-12 w-full rounded-xl border border-slate-200 bg-slate-50 px-4 text-sm outline-none transition focus:border-red-400 focus:bg-white">
                    <option value="">Choose user</option>
                    {users.map((user) => (
                      <option key={user.id} value={user.id}>{user.name} · {user.email} · {user.active_device_tokens_count} devices</option>
                    ))}
                  </select>
                </label>
              ) : null}
              <Field label="Title" value={form.title} onChange={(title) => setForm({ ...form, title })} required />
              <label className="block">
                <span className="mb-2 block text-sm font-medium text-slate-700">Message</span>
                <textarea required value={form.body} onChange={(event) => setForm({ ...form, body: event.target.value })} className="min-h-32 w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm outline-none focus:border-red-400 focus:bg-white" />
              </label>
              <div className="grid gap-4 md:grid-cols-2">
                <SelectField label="Action Type" value={form.action_type} onChange={(action_type) => setForm({ ...form, action_type })} options={['none', 'service', 'url']} />
                <Field label="Action Value" value={form.action_value} onChange={(action_value) => setForm({ ...form, action_value })} />
              </div>
              <button disabled={sending} className="rounded-xl bg-red-600 px-6 py-3 text-sm font-medium text-white hover:bg-red-700 disabled:opacity-60">
                {sending ? 'Sending...' : 'Send Push Notification'}
              </button>
            </div>
          </Panel>

          <Panel title="Registered Users">
            <div className="max-h-[520px] space-y-3 overflow-y-auto pr-1">
              {users.map((user) => (
                <div key={user.id} className="rounded-xl border border-slate-200 bg-slate-50 p-4">
                  <p className="font-medium text-slate-900">{user.name}</p>
                  <p className="mt-1 text-xs text-slate-500">{user.email}</p>
                  <div className="mt-3 flex items-center justify-between text-sm">
                    <StatusBadge status={user.status} />
                    <span className="text-slate-500">{user.active_device_tokens_count} devices</span>
                  </div>
                </div>
              ))}
              {!users.length ? <p className="text-sm text-slate-500">No users found.</p> : null}
            </div>
          </Panel>
        </form>
      )}
    </div>
  );
}

function ReferralAdminPage() {
  const [data, setData] = useState(null);
  const [form, setForm] = useState({
    referral_enabled: true,
    referral_referrer_bonus: '25',
    referral_new_user_bonus: '10',
  });
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [notice, setNotice] = useState('');
  const [error, setError] = useState('');

  useEffect(() => {
    loadReferrals();
  }, []);

  async function loadReferrals() {
    setLoading(true);
    setError('');
    try {
      const response = await api.get('/admin/referrals');
      setData(response.data);
      setForm({
        referral_enabled: response.data.settings.referral_enabled,
        referral_referrer_bonus: response.data.settings.referral_referrer_bonus?.toString() || '0',
        referral_new_user_bonus: response.data.settings.referral_new_user_bonus?.toString() || '0',
      });
    } catch (apiError) {
      setError(apiError.response?.data?.message || 'Could not load referral settings.');
    } finally {
      setLoading(false);
    }
  }

  async function saveSettings(event) {
    event.preventDefault();
    setSaving(true);
    setNotice('');
    setError('');
    try {
      const response = await api.put('/admin/referrals', form);
      setNotice(response.data.message);
      await loadReferrals();
    } catch (apiError) {
      const errors = apiError.response?.data?.errors;
      setError(errors ? Object.values(errors).flat()[0] : (apiError.response?.data?.message || 'Could not save referral settings.'));
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="space-y-5">
      <div className="rounded-[14px] border border-slate-200 bg-white p-5 shadow-sm">
        <div className="flex items-start gap-4">
          <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-red-50 text-red-600">
            <Gift size={22} />
          </div>
          <div>
            <p className="text-xs uppercase tracking-[0.2em] text-red-600">Growth Campaign</p>
            <h2 className="mt-2 text-2xl font-medium text-slate-950">Referral System</h2>
            <p className="mt-1 text-sm text-slate-500">Control invite rewards and monitor referred users.</p>
          </div>
        </div>
      </div>

      {notice ? <div className="rounded-xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-700">{notice}</div> : null}
      {error ? <ErrorBlock message={error} /> : null}

      {loading ? <LoadingBlock label="Loading referral campaign..." /> : (
        <div className="grid gap-5 lg:grid-cols-[1fr_1.3fr]">
          <Panel title="Reward Settings">
            <form onSubmit={saveSettings} className="space-y-4">
              <label className="flex items-center justify-between rounded-xl border border-slate-200 bg-slate-50 px-4 py-3">
                <span className="text-sm font-medium text-slate-800">Referral campaign active</span>
                <input type="checkbox" checked={Boolean(form.referral_enabled)} onChange={(event) => setForm({ ...form, referral_enabled: event.target.checked })} className="h-5 w-5 accent-red-600" />
              </label>
              <Field label="Referrer Bonus" type="number" value={form.referral_referrer_bonus} onChange={(value) => setForm({ ...form, referral_referrer_bonus: value })} />
              <Field label="New User Bonus" type="number" value={form.referral_new_user_bonus} onChange={(value) => setForm({ ...form, referral_new_user_bonus: value })} />
              <button disabled={saving} className="w-full rounded-xl bg-red-600 px-5 py-3 text-sm font-medium text-white hover:bg-red-700 disabled:opacity-60">{saving ? 'Saving...' : 'Save Referral Settings'}</button>
            </form>
          </Panel>
          <Panel title="Referral Overview">
            <div className="grid gap-3 sm:grid-cols-2">
              {[
                ['Referred Users', data?.stats?.referred_users || 0],
                ['Total Bonus', formatMoney(data?.stats?.total_bonus || 0)],
              ].map(([label, value]) => (
                <div key={label} className="rounded-[12px] border border-slate-200 bg-slate-50 p-4">
                  <p className="text-sm text-slate-500">{label}</p>
                  <p className="mt-2 text-2xl font-medium text-slate-950">{value}</p>
                </div>
              ))}
            </div>
            <div className="mt-5 space-y-2">
              {(data?.recent_referrals || []).map((user) => (
                <div key={user.id} className="rounded-xl border border-slate-200 bg-slate-50 p-4">
                  <div className="flex items-start justify-between gap-3">
                    <div>
                      <p className="font-medium text-slate-950">{user.name}</p>
                      <p className="mt-1 text-xs text-slate-500">{user.email}</p>
                      <p className="mt-1 text-xs text-slate-500">Invited by {user.referred_by?.name || 'Unknown'}</p>
                    </div>
                    <span className="rounded-full bg-emerald-50 px-3 py-1 text-xs font-medium text-emerald-700">{formatMoney(user.referral_bonus_earned || 0)}</span>
                  </div>
                </div>
              ))}
              {!data?.recent_referrals?.length ? <p className="rounded-xl border border-slate-200 bg-slate-50 p-5 text-sm text-slate-500">No referrals yet.</p> : null}
            </div>
          </Panel>
        </div>
      )}
    </div>
  );
}

function GeneralSettingsPage() {
  const [form, setForm] = useState({
    youtube_url: '',
    telegram_url: '',
    maintenance_mode: false,
    add_money_enabled: true,
    add_money_min_amount: '10',
    add_money_max_amount: '500000',
    mobile_recharge_enabled: true,
    mobile_recharge_charge: '0',
    mobile_recharge_min_amount: '10',
    mobile_recharge_max_amount: '50000',
    bill_payment_enabled: true,
    bill_payment_charge: '0',
    bill_payment_min_amount: '10',
    bill_payment_max_amount: '500000',
    bank_transfer_enabled: true,
    bank_transfer_charge: '0',
    bank_transfer_min_amount: '100',
    bank_transfer_max_amount: '500000',
    wallet_withdrawal_enabled: true,
    wallet_withdrawal_charge: '0',
    wallet_withdrawal_min_amount: '50',
    wallet_withdrawal_max_amount: '500000',
  });
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [notice, setNotice] = useState('');
  const [error, setError] = useState('');

  useEffect(() => {
    loadSettings();
  }, []);

  async function loadSettings() {
    setLoading(true);
    setError('');
    try {
      const response = await api.get('/admin/general-settings');
      setForm({
        youtube_url: response.data.settings?.youtube_url || '',
        telegram_url: response.data.settings?.telegram_url || '',
        maintenance_mode: Boolean(response.data.settings?.maintenance_mode),
        add_money_enabled: response.data.settings?.add_money_enabled !== false,
        add_money_min_amount: response.data.settings?.add_money_min_amount?.toString() || '10',
        add_money_max_amount: response.data.settings?.add_money_max_amount?.toString() || '500000',
        mobile_recharge_enabled: response.data.settings?.mobile_recharge_enabled !== false,
        mobile_recharge_charge: response.data.settings?.mobile_recharge_charge?.toString() || '0',
        mobile_recharge_min_amount: response.data.settings?.mobile_recharge_min_amount?.toString() || '10',
        mobile_recharge_max_amount: response.data.settings?.mobile_recharge_max_amount?.toString() || '50000',
        bill_payment_enabled: response.data.settings?.bill_payment_enabled !== false,
        bill_payment_charge: response.data.settings?.bill_payment_charge?.toString() || '0',
        bill_payment_min_amount: response.data.settings?.bill_payment_min_amount?.toString() || '10',
        bill_payment_max_amount: response.data.settings?.bill_payment_max_amount?.toString() || '500000',
        bank_transfer_enabled: response.data.settings?.bank_transfer_enabled !== false,
        bank_transfer_charge: response.data.settings?.bank_transfer_charge?.toString() || '0',
        bank_transfer_min_amount: response.data.settings?.bank_transfer_min_amount?.toString() || '100',
        bank_transfer_max_amount: response.data.settings?.bank_transfer_max_amount?.toString() || '500000',
        wallet_withdrawal_enabled: response.data.settings?.wallet_withdrawal_enabled !== false,
        wallet_withdrawal_charge: response.data.settings?.wallet_withdrawal_charge?.toString() || '0',
        wallet_withdrawal_min_amount: response.data.settings?.wallet_withdrawal_min_amount?.toString() || '50',
        wallet_withdrawal_max_amount: response.data.settings?.wallet_withdrawal_max_amount?.toString() || '500000',
      });
    } catch (apiError) {
      setError(apiError.response?.data?.message || 'Could not load general settings.');
    } finally {
      setLoading(false);
    }
  }

  async function saveSettings(event) {
    event.preventDefault();
    setSaving(true);
    setNotice('');
    setError('');
    try {
      const response = await api.put('/admin/general-settings', form);
      setForm({
        youtube_url: response.data.settings?.youtube_url || '',
        telegram_url: response.data.settings?.telegram_url || '',
        maintenance_mode: Boolean(response.data.settings?.maintenance_mode),
        add_money_enabled: response.data.settings?.add_money_enabled !== false,
        add_money_min_amount: response.data.settings?.add_money_min_amount?.toString() || '10',
        add_money_max_amount: response.data.settings?.add_money_max_amount?.toString() || '500000',
        mobile_recharge_enabled: response.data.settings?.mobile_recharge_enabled !== false,
        mobile_recharge_charge: response.data.settings?.mobile_recharge_charge?.toString() || '0',
        mobile_recharge_min_amount: response.data.settings?.mobile_recharge_min_amount?.toString() || '10',
        mobile_recharge_max_amount: response.data.settings?.mobile_recharge_max_amount?.toString() || '50000',
        bill_payment_enabled: response.data.settings?.bill_payment_enabled !== false,
        bill_payment_charge: response.data.settings?.bill_payment_charge?.toString() || '0',
        bill_payment_min_amount: response.data.settings?.bill_payment_min_amount?.toString() || '10',
        bill_payment_max_amount: response.data.settings?.bill_payment_max_amount?.toString() || '500000',
        bank_transfer_enabled: response.data.settings?.bank_transfer_enabled !== false,
        bank_transfer_charge: response.data.settings?.bank_transfer_charge?.toString() || '0',
        bank_transfer_min_amount: response.data.settings?.bank_transfer_min_amount?.toString() || '100',
        bank_transfer_max_amount: response.data.settings?.bank_transfer_max_amount?.toString() || '500000',
        wallet_withdrawal_enabled: response.data.settings?.wallet_withdrawal_enabled !== false,
        wallet_withdrawal_charge: response.data.settings?.wallet_withdrawal_charge?.toString() || '0',
        wallet_withdrawal_min_amount: response.data.settings?.wallet_withdrawal_min_amount?.toString() || '50',
        wallet_withdrawal_max_amount: response.data.settings?.wallet_withdrawal_max_amount?.toString() || '500000',
      });
      setNotice(response.data.message);
    } catch (apiError) {
      const errors = apiError.response?.data?.errors;
      setError(errors ? Object.values(errors).flat()[0] : (apiError.response?.data?.message || 'Could not save general settings.'));
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="space-y-5">
      <div className="rounded-[14px] border border-slate-200 bg-white p-5 shadow-sm">
        <div className="flex items-start gap-4">
          <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-red-50 text-red-600">
            <Settings size={22} />
          </div>
          <div>
            <p className="text-xs uppercase tracking-[0.2em] text-red-600">App Controls</p>
            <h2 className="mt-2 text-2xl font-medium text-slate-950">General Settings</h2>
            <p className="mt-1 text-sm text-slate-500">Control app availability, service charges and social links.</p>
          </div>
        </div>
      </div>

      {notice ? <div className="rounded-xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-700">{notice}</div> : null}
      {error ? <ErrorBlock message={error} /> : null}

      {loading ? <LoadingBlock label="Loading general settings..." /> : (
        <form onSubmit={saveSettings}>
          <Panel title="Maintenance Mode">
            <label className="flex flex-col gap-4 rounded-xl border border-slate-200 bg-slate-50 p-4 sm:flex-row sm:items-center sm:justify-between">
              <div>
                <p className="text-sm font-medium text-slate-900">Maintenance Mode</p>
                <p className="mt-1 text-sm text-slate-500">When enabled, app transaction requests are blocked safely.</p>
              </div>
              <input
                type="checkbox"
                checked={form.maintenance_mode}
                onChange={(event) => setForm({ ...form, maintenance_mode: event.target.checked })}
                className="h-5 w-5 accent-red-600"
              />
            </label>
          </Panel>

          <Panel title="Service Availability & Charges">
            <div className="grid gap-4 lg:grid-cols-2">
              <ServiceControlField
                title="Add Money"
                enabled={form.add_money_enabled}
                charge="0"
                minAmount={form.add_money_min_amount}
                maxAmount={form.add_money_max_amount}
                hideCharge
                onEnabledChange={(add_money_enabled) => setForm({ ...form, add_money_enabled })}
                onChargeChange={() => {}}
                onMinChange={(add_money_min_amount) => setForm({ ...form, add_money_min_amount })}
                onMaxChange={(add_money_max_amount) => setForm({ ...form, add_money_max_amount })}
              />
              <ServiceControlField
                title="Mobile Recharge"
                enabled={form.mobile_recharge_enabled}
                charge={form.mobile_recharge_charge}
                minAmount={form.mobile_recharge_min_amount}
                maxAmount={form.mobile_recharge_max_amount}
                onEnabledChange={(mobile_recharge_enabled) => setForm({ ...form, mobile_recharge_enabled })}
                onChargeChange={(mobile_recharge_charge) => setForm({ ...form, mobile_recharge_charge })}
                onMinChange={(mobile_recharge_min_amount) => setForm({ ...form, mobile_recharge_min_amount })}
                onMaxChange={(mobile_recharge_max_amount) => setForm({ ...form, mobile_recharge_max_amount })}
              />
              <ServiceControlField
                title="Bill Payment"
                enabled={form.bill_payment_enabled}
                charge={form.bill_payment_charge}
                minAmount={form.bill_payment_min_amount}
                maxAmount={form.bill_payment_max_amount}
                onEnabledChange={(bill_payment_enabled) => setForm({ ...form, bill_payment_enabled })}
                onChargeChange={(bill_payment_charge) => setForm({ ...form, bill_payment_charge })}
                onMinChange={(bill_payment_min_amount) => setForm({ ...form, bill_payment_min_amount })}
                onMaxChange={(bill_payment_max_amount) => setForm({ ...form, bill_payment_max_amount })}
              />
              <ServiceControlField
                title="Bank Transfer"
                enabled={form.bank_transfer_enabled}
                charge={form.bank_transfer_charge}
                minAmount={form.bank_transfer_min_amount}
                maxAmount={form.bank_transfer_max_amount}
                onEnabledChange={(bank_transfer_enabled) => setForm({ ...form, bank_transfer_enabled })}
                onChargeChange={(bank_transfer_charge) => setForm({ ...form, bank_transfer_charge })}
                onMinChange={(bank_transfer_min_amount) => setForm({ ...form, bank_transfer_min_amount })}
                onMaxChange={(bank_transfer_max_amount) => setForm({ ...form, bank_transfer_max_amount })}
              />
              <ServiceControlField
                title="Wallet Withdrawal"
                enabled={form.wallet_withdrawal_enabled}
                charge={form.wallet_withdrawal_charge}
                minAmount={form.wallet_withdrawal_min_amount}
                maxAmount={form.wallet_withdrawal_max_amount}
                onEnabledChange={(wallet_withdrawal_enabled) => setForm({ ...form, wallet_withdrawal_enabled })}
                onChargeChange={(wallet_withdrawal_charge) => setForm({ ...form, wallet_withdrawal_charge })}
                onMinChange={(wallet_withdrawal_min_amount) => setForm({ ...form, wallet_withdrawal_min_amount })}
                onMaxChange={(wallet_withdrawal_max_amount) => setForm({ ...form, wallet_withdrawal_max_amount })}
              />
            </div>
            <p className="mt-4 rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm text-slate-500">
              Default charge is BDT 0. Set any charge amount or turn a service off anytime.
            </p>
          </Panel>

          <Panel title="Social Service Links">
            <div className="grid gap-4 md:grid-cols-2">
              <SocialLinkField
                icon={Youtube}
                label="YouTube Link"
                value={form.youtube_url}
                placeholder="https://youtube.com/@citygoremit"
                onChange={(youtube_url) => setForm({ ...form, youtube_url })}
              />
              <SocialLinkField
                icon={Send}
                label="Telegram Link"
                value={form.telegram_url}
                placeholder="https://t.me/citygoremit"
                onChange={(telegram_url) => setForm({ ...form, telegram_url })}
              />
            </div>
            <p className="mt-4 rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm text-slate-500">
              If a link is empty, the app shows a clean unavailable message instead of opening anything.
            </p>
            <button disabled={saving} className="mt-5 rounded-xl bg-red-600 px-6 py-3 text-sm font-medium text-white hover:bg-red-700 disabled:opacity-60">
              {saving ? 'Saving...' : 'Save General Settings'}
            </button>
          </Panel>
        </form>
      )}
    </div>
  );
}

function ServiceControlField({ title, enabled, charge, minAmount, maxAmount, hideCharge = false, onEnabledChange, onChargeChange, onMinChange, onMaxChange }) {
  return (
    <div className="rounded-xl border border-slate-200 bg-slate-50 p-4">
      <div className="flex items-center justify-between gap-3">
        <div>
          <p className="text-sm font-medium text-slate-900">{title}</p>
          <p className="mt-1 text-xs text-slate-500">{enabled ? 'Available in app' : 'Currently off'}</p>
        </div>
        <input
          type="checkbox"
          checked={enabled}
          onChange={(event) => onEnabledChange(event.target.checked)}
          className="h-5 w-5 accent-red-600"
        />
      </div>
      <div className="mt-4 grid gap-3 sm:grid-cols-3">
        {!hideCharge ? (
          <label className="block">
            <span className="text-xs font-medium uppercase tracking-[0.14em] text-slate-500">Charge</span>
            <input
              type="number"
              min="0"
              step="0.01"
              value={charge}
              onChange={(event) => onChargeChange(event.target.value)}
              className="mt-2 h-12 w-full rounded-xl border border-slate-200 bg-white px-4 text-sm outline-none transition focus:border-red-400"
            />
          </label>
        ) : null}
        <label className="block">
          <span className="text-xs font-medium uppercase tracking-[0.14em] text-slate-500">Minimum</span>
          <input
            type="number"
            min="0"
            step="0.01"
            value={minAmount}
            onChange={(event) => onMinChange(event.target.value)}
            className="mt-2 h-12 w-full rounded-xl border border-slate-200 bg-white px-4 text-sm outline-none transition focus:border-red-400"
          />
        </label>
        <label className="block">
          <span className="text-xs font-medium uppercase tracking-[0.14em] text-slate-500">Maximum</span>
          <input
            type="number"
            min="0"
            step="0.01"
            value={maxAmount}
            onChange={(event) => onMaxChange(event.target.value)}
            className="mt-2 h-12 w-full rounded-xl border border-slate-200 bg-white px-4 text-sm outline-none transition focus:border-red-400"
          />
        </label>
      </div>
    </div>
  );
}

function SocialLinkField({ icon: Icon, label, value, onChange, placeholder }) {
  return (
    <label className="block rounded-xl border border-slate-200 bg-slate-50 p-4">
      <span className="flex items-center gap-2 text-sm font-medium text-slate-700">
        <Icon size={18} className="text-red-600" />
        {label}
      </span>
      <input
        type="url"
        value={value}
        placeholder={placeholder}
        onChange={(event) => onChange(event.target.value)}
        className="mt-3 h-12 w-full rounded-xl border border-slate-200 bg-white px-4 text-sm outline-none transition focus:border-red-400"
      />
    </label>
  );
}

const emptyBannerForm = {
  title: '',
  subtitle: '',
  button_text: '',
  action_type: 'none',
  action_value: '',
  is_active: true,
  sort_order: '0',
  starts_at: '',
  ends_at: '',
};

function BannersPage() {
  const [data, setData] = useState(null);
  const [query, setQuery] = useState({ search: '', status: '' });
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [notice, setNotice] = useState('');
  const [editing, setEditing] = useState(null);
  const [modalOpen, setModalOpen] = useState(false);
  const [form, setForm] = useState(emptyBannerForm);
  const [imageFile, setImageFile] = useState(null);
  const [cropSource, setCropSource] = useState(null);

  useEffect(() => {
    load();
  }, []);

  async function load(nextQuery = query) {
    setLoading(true);
    setError('');
    try {
      const response = await api.get('/admin/banners', { params: nextQuery });
      setData(response.data);
    } catch (apiError) {
      setError(apiError.response?.data?.message || 'Could not load banners.');
    } finally {
      setLoading(false);
    }
  }

  function openCreate() {
    setEditing(null);
    setForm(emptyBannerForm);
    setImageFile(null);
    setModalOpen(true);
  }

  function openEdit(banner) {
    setEditing(banner);
    setForm({
      title: banner.title || '',
      subtitle: banner.subtitle || '',
      button_text: banner.button_text || '',
      action_type: banner.action_type || 'none',
      action_value: banner.action_value || '',
      is_active: Boolean(banner.is_active),
      sort_order: banner.sort_order || '0',
      starts_at: banner.starts_at?.slice(0, 10) || '',
      ends_at: banner.ends_at?.slice(0, 10) || '',
    });
    setImageFile(null);
    setModalOpen(true);
  }

  function chooseImage(file) {
    if (!file || !file.type.startsWith('image/')) return;
    setCropSource({
      file,
      name: file.name,
      src: URL.createObjectURL(file),
    });
  }

  async function saveBanner(event) {
    event.preventDefault();
    setSaving(true);
    setError('');
    setNotice('');

    const payload = new FormData();
    Object.entries(form).forEach(([key, value]) => {
      payload.append(key, typeof value === 'boolean' ? (value ? '1' : '0') : (value ?? ''));
    });
    if (imageFile) payload.append('image', imageFile, imageFile.name);

    try {
      const response = editing
        ? await api.post(`/admin/banners/${editing.id}`, payload)
        : await api.post('/admin/banners', payload);
      setNotice(response.data.message);
      setEditing(null);
      setModalOpen(false);
      setForm(emptyBannerForm);
      setImageFile(null);
      await load();
    } catch (apiError) {
      const errors = apiError.response?.data?.errors;
      setError(errors ? Object.values(errors).flat()[0] : (apiError.response?.data?.message || 'Could not save banner.'));
    } finally {
      setSaving(false);
    }
  }

  async function deleteBanner(banner) {
    if (!window.confirm(`Delete ${banner.title}?`)) return;
    setSaving(true);
    setError('');
    try {
      await api.delete(`/admin/banners/${banner.id}`);
      setNotice('Banner deleted successfully.');
      await load();
    } catch (apiError) {
      setError(apiError.response?.data?.message || 'Could not delete banner.');
    } finally {
      setSaving(false);
    }
  }

  const banners = data?.banners?.data || [];

  return (
    <div className="space-y-5">
      <div className="rounded-[14px] border border-slate-200 bg-white p-5 shadow-sm">
        <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
          <div>
            <p className="text-xs uppercase tracking-[0.2em] text-red-600">Home Experience</p>
            <h2 className="mt-2 text-2xl font-medium text-slate-950">App Banners</h2>
            <p className="mt-1 text-sm text-slate-500">Upload compact 960×320 banners and control what users see on the app home page.</p>
          </div>
          <button onClick={openCreate} className="inline-flex items-center justify-center gap-2 rounded-xl bg-red-600 px-5 py-3 text-sm font-medium text-white hover:bg-red-700">
            <Plus size={17} /> Add Banner
          </button>
        </div>
      </div>

      {data?.stats ? (
        <div className="grid gap-4 md:grid-cols-3">
          {[
            ['Total Banners', data.stats.total],
            ['Active', data.stats.active],
            ['Inactive', data.stats.inactive],
          ].map(([label, value]) => (
            <div key={label} className="rounded-[12px] border border-slate-200 bg-white p-4 shadow-sm">
              <p className="text-sm text-slate-500">{label}</p>
              <p className="mt-2 text-2xl font-medium text-slate-950">{value}</p>
            </div>
          ))}
        </div>
      ) : null}

      <Panel title="Filters">
        <div className="grid gap-3 md:grid-cols-[1fr_180px_auto]">
          <Field label="Search" value={query.search} onChange={(search) => setQuery({ ...query, search })} />
          <SelectField label="Status" value={query.status} onChange={(status) => setQuery({ ...query, status })} options={['', 'active', 'inactive']} />
          <button onClick={() => load()} className="self-end rounded-xl border border-slate-200 px-5 py-3 text-sm font-medium text-slate-700 hover:bg-slate-50">Filter</button>
        </div>
      </Panel>

      {notice ? <div className="rounded-xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-700">{notice}</div> : null}
      {error ? <ErrorBlock message={error} /> : null}

      {loading ? <LoadingBlock label="Loading banners..." /> : (
        <div className="grid gap-4 lg:grid-cols-2">
          {banners.map((banner) => (
            <div key={banner.id} className="overflow-hidden rounded-[14px] border border-slate-200 bg-white shadow-sm">
              <img src={banner.image_url} alt={banner.title} className="h-36 w-full object-cover" />
              <div className="p-4">
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <h3 className="text-lg font-medium text-slate-950">{banner.title}</h3>
                    <p className="mt-1 text-sm text-slate-500">{banner.subtitle || 'No subtitle'}</p>
                  </div>
                  <StatusBadge status={banner.is_active ? 'active' : 'inactive'} />
                </div>
                <div className="mt-4 grid gap-2 text-sm text-slate-500 sm:grid-cols-2">
                  <p>Action: <span className="font-medium text-slate-800">{banner.action_type}</span></p>
                  <p>Sort: <span className="font-medium text-slate-800">{banner.sort_order}</span></p>
                </div>
                <div className="mt-4 flex justify-end gap-2">
                  <button onClick={() => openEdit(banner)} className="rounded-xl border border-slate-200 p-2 text-slate-600 hover:bg-slate-50"><Edit3 size={16} /></button>
                  <button disabled={saving} onClick={() => deleteBanner(banner)} className="rounded-xl border border-red-200 p-2 text-red-600 hover:bg-red-50"><Trash2 size={16} /></button>
                </div>
              </div>
            </div>
          ))}
          {!banners.length ? <div className="rounded-[14px] border border-slate-200 bg-white p-8 text-center text-slate-500">No banners found.</div> : null}
        </div>
      )}

      {modalOpen ? (
        <BannerModal
          form={form}
          editing={editing}
          imageFile={imageFile}
          saving={saving}
          setForm={setForm}
          onChooseImage={chooseImage}
          onClose={() => { setModalOpen(false); setEditing(null); setImageFile(null); setForm(emptyBannerForm); }}
          onSubmit={saveBanner}
        />
      ) : null}

      {cropSource ? (
        <BannerImageCropper
          image={cropSource}
          onClose={() => {
            URL.revokeObjectURL(cropSource.src);
            setCropSource(null);
          }}
          onSave={(file) => {
            URL.revokeObjectURL(cropSource.src);
            setImageFile(file);
            setCropSource(null);
          }}
        />
      ) : null}
    </div>
  );
}

function BannerModal({ form, editing, imageFile, saving, setForm, onChooseImage, onClose, onSubmit }) {
  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-slate-950/45 p-3 sm:items-center">
      <form onSubmit={onSubmit} className="max-h-[92vh] w-full max-w-3xl overflow-y-auto rounded-[14px] border border-slate-200 bg-white p-5 shadow-sm">
        <div className="flex items-start justify-between gap-4">
          <div>
            <h3 className="text-xl font-medium text-slate-950">{editing ? 'Edit Banner' : 'Add Banner'}</h3>
            <p className="mt-1 text-sm text-slate-500">Image will be cropped to fixed 960×320 before upload.</p>
          </div>
          <button type="button" onClick={onClose} className="rounded-xl border border-slate-200 p-2 text-slate-500"><X size={18} /></button>
        </div>

        <div className="mt-5 grid gap-4 md:grid-cols-2">
          <Field label="Title" value={form.title} onChange={(title) => setForm({ ...form, title })} required />
          <Field label="Subtitle" value={form.subtitle} onChange={(subtitle) => setForm({ ...form, subtitle })} />
          <Field label="Button Text" value={form.button_text} onChange={(button_text) => setForm({ ...form, button_text })} />
          <SelectField label="Action Type" value={form.action_type} onChange={(action_type) => setForm({ ...form, action_type })} options={['none', 'service', 'url']} />
          <Field label="Action Value" value={form.action_value} onChange={(action_value) => setForm({ ...form, action_value })} />
          <Field label="Sort Order" type="number" value={form.sort_order} onChange={(sort_order) => setForm({ ...form, sort_order })} />
          <Field label="Starts At" type="date" value={form.starts_at} onChange={(starts_at) => setForm({ ...form, starts_at })} />
          <Field label="Ends At" type="date" value={form.ends_at} onChange={(ends_at) => setForm({ ...form, ends_at })} />
        </div>

        <div className="mt-4 rounded-xl border border-slate-200 bg-slate-50 p-4">
          <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <p className="text-sm font-medium text-slate-900">Banner Image</p>
              <p className="mt-1 text-xs text-slate-500">{imageFile ? imageFile.name : editing ? 'Current image will remain unless you upload a new one.' : 'Required · fixed crop 960×320'}</p>
            </div>
            <label className="inline-flex cursor-pointer items-center justify-center gap-2 rounded-xl border border-slate-200 bg-white px-4 py-3 text-sm font-medium text-slate-700 hover:bg-slate-100">
              <ImageIcon size={17} /> Select & Crop
              <input type="file" accept="image/*" className="hidden" onChange={(event) => onChooseImage(event.target.files?.[0])} />
            </label>
          </div>
        </div>

        <div className="mt-4">
          <ToggleField label="Active for App Users" checked={form.is_active} onChange={(is_active) => setForm({ ...form, is_active })} />
        </div>

        <div className="mt-6 flex flex-col-reverse gap-3 sm:flex-row sm:justify-end">
          <button type="button" onClick={onClose} className="rounded-xl border border-slate-200 px-5 py-3 text-sm text-slate-600 hover:bg-slate-50">Cancel</button>
          <button disabled={saving || (!editing && !imageFile)} className="rounded-xl bg-red-600 px-5 py-3 text-sm font-medium text-white hover:bg-red-700 disabled:opacity-60">
            {saving ? 'Saving...' : 'Save Banner'}
          </button>
        </div>
      </form>
    </div>
  );
}

function BannerImageCropper({ image, onClose, onSave }) {
  const canvasRef = useRef(null);
  const imageRef = useRef(null);
  const [scale, setScale] = useState(1);
  const [offset, setOffset] = useState({ x: 0, y: 0 });

  useEffect(() => {
    const img = new window.Image();
    img.onload = () => {
      imageRef.current = img;
      draw(img, scale, offset);
    };
    img.src = image.src;
  }, [image.src]);

  useEffect(() => {
    draw(imageRef.current, scale, offset);
  }, [scale, offset]);

  function draw(img, nextScale, nextOffset) {
    const canvas = canvasRef.current;
    if (!canvas || !img) return;
    const context = canvas.getContext('2d');
    context.clearRect(0, 0, canvas.width, canvas.height);
    context.fillStyle = '#f8fafc';
    context.fillRect(0, 0, canvas.width, canvas.height);

    const baseScale = Math.max(canvas.width / img.width, canvas.height / img.height);
    const drawWidth = img.width * baseScale * nextScale;
    const drawHeight = img.height * baseScale * nextScale;
    const x = (canvas.width - drawWidth) / 2 + nextOffset.x;
    const y = (canvas.height - drawHeight) / 2 + nextOffset.y;
    context.drawImage(img, x, y, drawWidth, drawHeight);
  }

  function move(dx, dy) {
    setOffset((current) => ({ x: current.x + dx, y: current.y + dy }));
  }

  function save() {
    const canvas = canvasRef.current;
    if (!canvas) return;
    canvas.toBlob((blob) => {
      if (!blob) return;
      onSave(new File([blob], `banner-${Date.now()}.png`, { type: 'image/png' }));
    }, 'image/png', 0.92);
  }

  return (
    <div className="fixed inset-0 z-[60] flex items-center justify-center bg-slate-950/70 p-3">
      <div className="w-full max-w-4xl rounded-[14px] bg-white p-5 shadow-sm">
        <div className="flex items-start justify-between gap-4">
          <div>
            <h3 className="text-xl font-medium text-slate-950">Crop Banner</h3>
            <p className="mt-1 text-sm text-slate-500">Fixed output: 960×320. Move and zoom until it looks clean.</p>
          </div>
          <button type="button" onClick={onClose} className="rounded-xl border border-slate-200 p-2 text-slate-500"><X size={18} /></button>
        </div>
        <div className="mt-5 overflow-hidden rounded-xl border border-slate-200 bg-slate-50">
          <canvas ref={canvasRef} width="960" height="320" className="block w-full" />
        </div>
        <div className="mt-4 grid gap-3 lg:grid-cols-[1fr_auto] lg:items-center">
          <input type="range" min="1" max="2.5" step="0.02" value={scale} onChange={(event) => setScale(Number(event.target.value))} />
          <div className="grid grid-cols-4 gap-2">
            <button type="button" onClick={() => move(0, -14)} className="rounded-xl border border-slate-200 px-3 py-2 text-sm">Up</button>
            <button type="button" onClick={() => move(0, 14)} className="rounded-xl border border-slate-200 px-3 py-2 text-sm">Down</button>
            <button type="button" onClick={() => move(-14, 0)} className="rounded-xl border border-slate-200 px-3 py-2 text-sm">Left</button>
            <button type="button" onClick={() => move(14, 0)} className="rounded-xl border border-slate-200 px-3 py-2 text-sm">Right</button>
          </div>
        </div>
        <div className="mt-5 flex justify-end gap-3">
          <button type="button" onClick={onClose} className="rounded-xl border border-slate-200 px-5 py-3 text-sm text-slate-600 hover:bg-slate-50">Cancel</button>
          <button type="button" onClick={save} className="rounded-xl bg-red-600 px-5 py-3 text-sm font-medium text-white hover:bg-red-700">Use Banner</button>
        </div>
      </div>
    </div>
  );
}

const emptyDriveOfferForm = {
  operator: 'Grameenphone',
  title: '',
  offer_type: 'internet',
  data_amount: '',
  minutes: '',
  sms: '',
  validity: '',
  price: '',
  service_charge: '0',
  activation_code: '',
  source_note: '',
  description: '',
  is_featured: false,
  is_active: true,
  sort_order: '0',
  starts_at: '',
  ends_at: '',
};

function DriveOffersPage() {
  const [data, setData] = useState(null);
  const [query, setQuery] = useState({ search: '', operator: '', status: '' });
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [notice, setNotice] = useState('');
  const [editing, setEditing] = useState(null);
  const [offerModalOpen, setOfferModalOpen] = useState(false);
  const [form, setForm] = useState(emptyDriveOfferForm);

  useEffect(() => {
    load();
  }, []);

  async function load(nextQuery = query) {
    setLoading(true);
    setError('');
    try {
      const response = await api.get('/admin/drive-offers', { params: nextQuery });
      setData(response.data);
    } catch (apiError) {
      setError(apiError.response?.data?.message || 'Could not load drive offers.');
    } finally {
      setLoading(false);
    }
  }

  function openCreate() {
    setEditing(null);
    setForm(emptyDriveOfferForm);
    setOfferModalOpen(true);
  }

  function openEdit(offer) {
    setEditing(offer);
    setOfferModalOpen(true);
    setForm({
      operator: offer.operator || 'Grameenphone',
      title: offer.title || '',
      offer_type: offer.offer_type || 'internet',
      data_amount: offer.data_amount || '',
      minutes: offer.minutes || '',
      sms: offer.sms || '',
      validity: offer.validity || '',
      price: offer.price || '',
      service_charge: offer.service_charge || '0',
      activation_code: offer.activation_code || '',
      source_note: offer.source_note || '',
      description: offer.description || '',
      is_featured: Boolean(offer.is_featured),
      is_active: Boolean(offer.is_active),
      sort_order: offer.sort_order || '0',
      starts_at: offer.starts_at?.slice(0, 10) || '',
      ends_at: offer.ends_at?.slice(0, 10) || '',
    });
  }

  async function saveOffer(event) {
    event.preventDefault();
    setSaving(true);
    setError('');
    setNotice('');

    const payload = {
      ...form,
      service_charge: form.service_charge || '0',
      sort_order: form.sort_order || '0',
      starts_at: form.starts_at || null,
      ends_at: form.ends_at || null,
    };

    try {
      const response = editing
        ? await api.put(`/admin/drive-offers/${editing.id}`, payload)
        : await api.post('/admin/drive-offers', payload);
      setNotice(response.data.message);
      setEditing(null);
      setOfferModalOpen(false);
      setForm(emptyDriveOfferForm);
      await load();
    } catch (apiError) {
      const errors = apiError.response?.data?.errors;
      setError(errors ? Object.values(errors).flat()[0] : (apiError.response?.data?.message || 'Could not save offer.'));
    } finally {
      setSaving(false);
    }
  }

  async function deleteOffer(offer) {
    if (!window.confirm(`Delete ${offer.title}?`)) return;
    setSaving(true);
    setError('');
    try {
      await api.delete(`/admin/drive-offers/${offer.id}`);
      setNotice('Drive offer deleted successfully.');
      await load();
    } catch (apiError) {
      setError(apiError.response?.data?.message || 'Could not delete offer.');
    } finally {
      setSaving(false);
    }
  }

  const offers = data?.offers?.data || [];
  const operators = data?.operators || ['Grameenphone', 'Robi', 'Airtel', 'Banglalink', 'Teletalk'];

  return (
    <div className="space-y-5">
      <div className="rounded-[14px] border border-slate-200 bg-white p-5 shadow-sm">
        <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
          <div>
            <p className="text-xs uppercase tracking-[0.2em] text-red-600">Admin Managed</p>
            <h2 className="mt-2 text-2xl font-medium text-slate-950">Drive Internet Offers</h2>
            <p className="mt-1 text-sm text-slate-500">Maintain all Bangladesh SIM internet offers without depending on unstable free APIs.</p>
          </div>
          <button onClick={openCreate} className="inline-flex items-center justify-center gap-2 rounded-xl bg-red-600 px-5 py-3 text-sm font-medium text-white hover:bg-red-700">
            <Plus size={17} /> Add Offer
          </button>
        </div>
      </div>

      {data?.stats ? (
        <div className="grid gap-4 md:grid-cols-4">
          {[
            ['Total Offers', data.stats.total],
            ['Active', data.stats.active],
            ['Featured', data.stats.featured],
            ['Operators', data.stats.operators],
          ].map(([label, value]) => (
            <div key={label} className="rounded-[12px] border border-slate-200 bg-white p-4 shadow-sm">
              <p className="text-sm text-slate-500">{label}</p>
              <p className="mt-2 text-2xl font-medium text-slate-950">{value}</p>
            </div>
          ))}
        </div>
      ) : null}

      <Panel title="Filters">
        <div className="grid gap-3 md:grid-cols-[1fr_180px_180px_auto]">
          <Field label="Search" value={query.search} onChange={(search) => setQuery({ ...query, search })} />
          <SelectField label="Operator" value={query.operator} onChange={(operator) => setQuery({ ...query, operator })} options={['', ...operators]} />
          <SelectField label="Status" value={query.status} onChange={(status) => setQuery({ ...query, status })} options={['', 'active', 'inactive']} />
          <button onClick={() => load()} className="self-end rounded-xl border border-slate-200 px-5 py-3 text-sm font-medium text-slate-700 hover:bg-slate-50">
            Filter
          </button>
        </div>
      </Panel>

      {notice ? <div className="rounded-xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-700">{notice}</div> : null}
      {error ? <ErrorBlock message={error} /> : null}

      {loading ? <LoadingBlock label="Loading drive offers..." /> : (
        <div className="overflow-hidden rounded-[14px] border border-slate-200 bg-white shadow-sm">
          <div className="overflow-x-auto">
            <table className="min-w-[980px] w-full text-left text-sm">
              <thead className="border-b border-slate-200 bg-slate-50 text-xs uppercase tracking-[0.14em] text-slate-500">
                <tr>
                  <th className="px-5 py-4">Offer</th>
                  <th className="py-4">Operator</th>
                  <th className="py-4">Data</th>
                  <th className="py-4">Validity</th>
                  <th className="py-4">Price</th>
                  <th className="py-4">Status</th>
                  <th className="py-4 text-right pr-5">Action</th>
                </tr>
              </thead>
              <tbody>
                {offers.map((offer) => (
                  <tr key={offer.id} className="border-b border-slate-100">
                    <td className="px-5 py-4">
                      <p className="font-medium text-slate-900">{offer.title}</p>
                      <p className="text-xs text-slate-500">{offer.activation_code || 'No code'} · {offer.source_note || 'Admin managed'}</p>
                    </td>
                    <td className="py-4 text-slate-600">{offer.operator}</td>
                    <td className="py-4 text-slate-600">{offer.data_amount || '-'}</td>
                    <td className="py-4 text-slate-600">{offer.validity}</td>
                    <td className="py-4 font-medium text-slate-900">{formatMoney(Number(offer.price) + Number(offer.service_charge || 0))}</td>
                    <td className="py-4"><StatusBadge status={offer.is_active ? 'active' : 'inactive'} /></td>
                    <td className="py-4 pr-5">
                      <div className="flex justify-end gap-2">
                        <button onClick={() => openEdit(offer)} className="rounded-xl border border-slate-200 p-2 text-slate-600 hover:bg-slate-50"><Edit3 size={16} /></button>
                        <button disabled={saving} onClick={() => deleteOffer(offer)} className="rounded-xl border border-red-200 p-2 text-red-600 hover:bg-red-50"><Trash2 size={16} /></button>
                      </div>
                    </td>
                  </tr>
                ))}
                {!offers.length ? <tr><td colSpan="7" className="px-5 py-10 text-center text-slate-500">No drive offers found.</td></tr> : null}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {offerModalOpen ? (
        <DriveOfferModal
          form={form}
          operators={operators}
          saving={saving}
          editing={editing}
          setForm={setForm}
          onClose={() => { setEditing(null); setOfferModalOpen(false); setForm(emptyDriveOfferForm); }}
          onSubmit={saveOffer}
        />
      ) : null}
    </div>
  );
}

function DriveOfferModal({ form, operators, saving, editing, setForm, onClose, onSubmit }) {
  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-slate-950/45 p-3 sm:items-center">
      <form onSubmit={onSubmit} className="max-h-[92vh] w-full max-w-3xl overflow-y-auto rounded-[14px] border border-slate-200 bg-white p-5 shadow-sm">
        <div className="flex items-start justify-between gap-4">
          <div>
            <h3 className="text-xl font-medium text-slate-950">{editing ? 'Edit Drive Offer' : 'Add Drive Offer'}</h3>
            <p className="mt-1 text-sm text-slate-500">Keep operator offers accurate, active and easy to purchase.</p>
          </div>
          <button type="button" onClick={onClose} className="rounded-xl border border-slate-200 p-2 text-slate-500"><X size={18} /></button>
        </div>

        <div className="mt-5 grid gap-4 md:grid-cols-2">
          <SelectField label="Operator" value={form.operator} onChange={(operator) => setForm({ ...form, operator })} options={operators} />
          <SelectField label="Offer Type" value={form.offer_type} onChange={(offer_type) => setForm({ ...form, offer_type })} options={['internet', 'bundle', 'social', 'unlimited']} />
          <Field label="Title" value={form.title} onChange={(title) => setForm({ ...form, title })} required />
          <Field label="Data Amount" value={form.data_amount} onChange={(data_amount) => setForm({ ...form, data_amount })} />
          <Field label="Validity" value={form.validity} onChange={(validity) => setForm({ ...form, validity })} required />
          <Field label="Price" type="number" value={form.price} onChange={(price) => setForm({ ...form, price })} required />
          <Field label="Service Charge" type="number" value={form.service_charge} onChange={(service_charge) => setForm({ ...form, service_charge })} />
          <Field label="Activation Code" value={form.activation_code} onChange={(activation_code) => setForm({ ...form, activation_code })} />
          <Field label="Minutes" value={form.minutes} onChange={(minutes) => setForm({ ...form, minutes })} />
          <Field label="SMS" value={form.sms} onChange={(sms) => setForm({ ...form, sms })} />
          <Field label="Source Note" value={form.source_note} onChange={(source_note) => setForm({ ...form, source_note })} />
          <Field label="Sort Order" type="number" value={form.sort_order} onChange={(sort_order) => setForm({ ...form, sort_order })} />
          <Field label="Starts At" type="date" value={form.starts_at} onChange={(starts_at) => setForm({ ...form, starts_at })} />
          <Field label="Ends At" type="date" value={form.ends_at} onChange={(ends_at) => setForm({ ...form, ends_at })} />
        </div>

        <label className="mt-4 block">
          <span className="mb-2 block text-sm font-medium text-slate-700">Description</span>
          <textarea value={form.description} onChange={(event) => setForm({ ...form, description: event.target.value })} className="min-h-24 w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm outline-none focus:border-red-400 focus:bg-white" />
        </label>

        <div className="mt-4 grid gap-3 sm:grid-cols-2">
          <ToggleField label="Featured Offer" checked={form.is_featured} onChange={(is_featured) => setForm({ ...form, is_featured })} />
          <ToggleField label="Active for App Users" checked={form.is_active} onChange={(is_active) => setForm({ ...form, is_active })} />
        </div>

        <div className="mt-6 flex flex-col-reverse gap-3 sm:flex-row sm:justify-end">
          <button type="button" onClick={onClose} className="rounded-xl border border-slate-200 px-5 py-3 text-sm text-slate-600 hover:bg-slate-50">Cancel</button>
          <button disabled={saving} className="rounded-xl bg-red-600 px-5 py-3 text-sm font-medium text-white hover:bg-red-700 disabled:opacity-60">
            {saving ? 'Saving...' : 'Save Offer'}
          </button>
        </div>
      </form>
    </div>
  );
}

function DriveOfferOrdersPage() {
  const [data, setData] = useState(null);
  const [query, setQuery] = useState({ search: '', status: '', operator: '' });
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState(null);

  useEffect(() => {
    load();
  }, []);

  async function load(nextQuery = query) {
    setLoading(true);
    setError('');
    try {
      const response = await api.get('/admin/drive-offer-orders', { params: nextQuery });
      setData(response.data);
    } catch (apiError) {
      setError(apiError.response?.data?.message || 'Could not load offer orders.');
    } finally {
      setLoading(false);
    }
  }

  function openEdit(order) {
    setEditing(order);
    setForm({
      mobile_number: order.mobile_number || '',
      operator: order.operator || '',
      offer_title: order.offer_title || '',
      data_amount: order.data_amount || '',
      validity: order.validity || '',
      price: order.price || '',
      service_charge: order.service_charge || '0',
      status: order.status || 'pending',
      admin_note: order.admin_note || '',
    });
  }

  async function quickStatus(order, status) {
    setSaving(true);
    try {
      await api.put(`/admin/drive-offer-orders/${order.id}`, {
        mobile_number: order.mobile_number,
        operator: order.operator,
        offer_title: order.offer_title,
        data_amount: order.data_amount || '',
        validity: order.validity,
        price: order.price,
        service_charge: order.service_charge || 0,
        status,
        admin_note: order.admin_note || `Marked as ${status} by admin.`,
      });
      await load();
    } catch (apiError) {
      setError(apiError.response?.data?.message || 'Could not update order.');
    } finally {
      setSaving(false);
    }
  }

  async function saveOrder(event) {
    event.preventDefault();
    setSaving(true);
    try {
      await api.put(`/admin/drive-offer-orders/${editing.id}`, form);
      setEditing(null);
      setForm(null);
      await load();
    } catch (apiError) {
      const errors = apiError.response?.data?.errors;
      setError(errors ? Object.values(errors).flat()[0] : (apiError.response?.data?.message || 'Could not save order.'));
    } finally {
      setSaving(false);
    }
  }

  const orders = data?.orders?.data || [];

  return (
    <div className="space-y-5">
      <div className="rounded-[14px] border border-slate-200 bg-white p-5 shadow-sm">
        <h2 className="text-2xl font-medium text-slate-950">Internet Offer Orders</h2>
        <p className="mt-1 text-sm text-slate-500">Approve, process, fail or refund OTP-confirmed user offer requests.</p>
      </div>

      {data?.stats ? (
        <div className="grid gap-4 md:grid-cols-4">
          {[
            ['Total', data.stats.total],
            ['Successful', data.stats.successful],
            ['Pending', data.stats.pending],
            ['Volume', formatMoney(data.stats.volume)],
          ].map(([label, value]) => (
            <div key={label} className="rounded-[12px] border border-slate-200 bg-white p-4 shadow-sm">
              <p className="text-sm text-slate-500">{label}</p>
              <p className="mt-2 text-2xl font-medium text-slate-950">{value}</p>
            </div>
          ))}
        </div>
      ) : null}

      <Panel title="Filters">
        <div className="grid gap-3 md:grid-cols-[1fr_180px_180px_auto]">
          <Field label="Search" value={query.search} onChange={(search) => setQuery({ ...query, search })} />
          <SelectField label="Status" value={query.status} onChange={(status) => setQuery({ ...query, status })} options={['', ...(data?.statuses || ['pending', 'processing', 'successful', 'failed', 'refunded', 'cancelled'])]} />
          <SelectField label="Operator" value={query.operator} onChange={(operator) => setQuery({ ...query, operator })} options={['', 'Grameenphone', 'Robi', 'Airtel', 'Banglalink', 'Teletalk']} />
          <button onClick={() => load()} className="self-end rounded-xl border border-slate-200 px-5 py-3 text-sm font-medium text-slate-700 hover:bg-slate-50">Filter</button>
        </div>
      </Panel>

      {error ? <ErrorBlock message={error} /> : null}

      {loading ? <LoadingBlock label="Loading internet offer orders..." /> : (
        <div className="overflow-hidden rounded-[14px] border border-slate-200 bg-white shadow-sm">
          <div className="overflow-x-auto">
            <table className="min-w-[1040px] w-full text-left text-sm">
              <thead className="border-b border-slate-200 bg-slate-50 text-xs uppercase tracking-[0.14em] text-slate-500">
                <tr>
                  <th className="px-5 py-4">Transaction</th>
                  <th className="py-4">User</th>
                  <th className="py-4">Number</th>
                  <th className="py-4">Offer</th>
                  <th className="py-4">Amount</th>
                  <th className="py-4">Status</th>
                  <th className="py-4 text-right pr-5">Action</th>
                </tr>
              </thead>
              <tbody>
                {orders.map((order) => (
                  <tr key={order.id} className="border-b border-slate-100">
                    <td className="px-5 py-4">
                      <p className="font-medium text-slate-900">{order.transaction_id}</p>
                      <p className="text-xs text-slate-500">{formatDate(order.created_at)}</p>
                    </td>
                    <td className="py-4">
                      <p className="text-slate-900">{order.user?.name || 'App User'}</p>
                      <p className="text-xs text-slate-500">{order.email}</p>
                    </td>
                    <td className="py-4 text-slate-600">{order.mobile_number}<br /><span className="text-xs">{order.operator}</span></td>
                    <td className="py-4 text-slate-600">{order.offer_title}<br /><span className="text-xs">{order.data_amount} · {order.validity}</span></td>
                    <td className="py-4 font-medium text-slate-900">{formatMoney(order.total_amount)}</td>
                    <td className="py-4"><StatusBadge status={order.status} /></td>
                    <td className="py-4 pr-5">
                      <div className="flex justify-end gap-2">
                        <button disabled={saving} onClick={() => quickStatus(order, 'successful')} className="rounded-xl border border-emerald-200 px-3 py-2 text-xs text-emerald-700 hover:bg-emerald-50">Success</button>
                        <button disabled={saving} onClick={() => quickStatus(order, 'failed')} className="rounded-xl border border-red-200 px-3 py-2 text-xs text-red-700 hover:bg-red-50">Fail</button>
                        <button onClick={() => openEdit(order)} className="rounded-xl border border-slate-200 p-2 text-slate-600 hover:bg-slate-50"><Edit3 size={16} /></button>
                      </div>
                    </td>
                  </tr>
                ))}
                {!orders.length ? <tr><td colSpan="7" className="px-5 py-10 text-center text-slate-500">No internet offer orders found.</td></tr> : null}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {editing && form ? (
        <div className="fixed inset-0 z-50 flex items-end justify-center bg-slate-950/45 p-3 sm:items-center">
          <form onSubmit={saveOrder} className="w-full max-w-2xl rounded-[14px] border border-slate-200 bg-white p-5 shadow-sm">
            <div className="flex items-start justify-between gap-4">
              <div>
                <h3 className="text-xl font-medium text-slate-950">Edit Offer Order</h3>
                <p className="mt-1 text-sm text-slate-500">{editing.transaction_id}</p>
              </div>
              <button type="button" onClick={() => { setEditing(null); setForm(null); }} className="rounded-xl border border-slate-200 p-2 text-slate-500"><X size={18} /></button>
            </div>
            <div className="mt-5 grid gap-4 md:grid-cols-2">
              <Field label="Mobile Number" value={form.mobile_number} onChange={(mobile_number) => setForm({ ...form, mobile_number })} required />
              <SelectField label="Status" value={form.status} onChange={(status) => setForm({ ...form, status })} options={data?.statuses || []} />
              <Field label="Offer Title" value={form.offer_title} onChange={(offer_title) => setForm({ ...form, offer_title })} required />
              <Field label="Data Amount" value={form.data_amount} onChange={(data_amount) => setForm({ ...form, data_amount })} />
              <Field label="Validity" value={form.validity} onChange={(validity) => setForm({ ...form, validity })} required />
              <Field label="Price" type="number" value={form.price} onChange={(price) => setForm({ ...form, price })} required />
              <Field label="Service Charge" type="number" value={form.service_charge} onChange={(service_charge) => setForm({ ...form, service_charge })} />
            </div>
            <label className="mt-4 block">
              <span className="mb-2 block text-sm font-medium text-slate-700">Admin Note</span>
              <textarea value={form.admin_note} onChange={(event) => setForm({ ...form, admin_note: event.target.value })} className="min-h-24 w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm outline-none focus:border-red-400 focus:bg-white" />
            </label>
            <div className="mt-6 flex flex-col-reverse gap-3 sm:flex-row sm:justify-end">
              <button type="button" onClick={() => { setEditing(null); setForm(null); }} className="rounded-xl border border-slate-200 px-5 py-3 text-sm text-slate-600 hover:bg-slate-50">Cancel</button>
              <button disabled={saving} className="rounded-xl bg-red-600 px-5 py-3 text-sm font-medium text-white hover:bg-red-700 disabled:opacity-60">{saving ? 'Saving...' : 'Save Order'}</button>
            </div>
          </form>
        </div>
      ) : null}
    </div>
  );
}

const exchangeRateFormDefaults = {
  country_name: '',
  country_code: '',
  country_flag: '',
  currency_code: '',
  currency_name: '',
  bdt_rate: '',
  service_fee: '0',
  delivery_time: '',
  note: '',
  is_active: true,
  sort_order: '0',
};

function ExchangeRatesPage() {
  const [rates, setRates] = useState([]);
  const [stats, setStats] = useState({ total: 0, active: 0, inactive: 0, average_rate: 0 });
  const [pagination, setPagination] = useState(null);
  const [query, setQuery] = useState({ search: '', status: 'all', page: 1 });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [notice, setNotice] = useState('');
  const [editing, setEditing] = useState(null);

  const loadRates = useCallback(async (nextQuery = query) => {
    setLoading(true);
    setError('');
    try {
      const response = await api.get('/admin/exchange-rates', { params: nextQuery });
      setRates(response.data?.rates?.data || []);
      setStats(response.data?.stats || { total: 0, active: 0, inactive: 0, average_rate: 0 });
      setPagination(response.data?.rates || null);
    } catch (apiError) {
      setError(apiError.response?.data?.message || 'Could not load exchange rates.');
    } finally {
      setLoading(false);
    }
  }, [query]);

  useEffect(() => {
    loadRates();
  }, [loadRates]);

  function updateQuery(patch) {
    const nextQuery = { ...query, ...patch, page: 1 };
    setQuery(nextQuery);
    loadRates(nextQuery);
  }

  async function deleteRate(rate) {
    if (!window.confirm(`Delete ${rate.country_name} exchange rate?`)) return;

    try {
      await api.delete(`/admin/exchange-rates/${rate.id}`);
      setNotice('Exchange rate deleted successfully.');
      loadRates();
    } catch (apiError) {
      setError(apiError.response?.data?.message || 'Could not delete exchange rate.');
    }
  }

  return (
    <div className="space-y-5">
      <div className="grid gap-4 md:grid-cols-4">
        {[
          ['Total Markets', stats.total || 0, 'Admin managed countries'],
          ['Active Rates', stats.active || 0, 'Visible in app'],
          ['Inactive Rates', stats.inactive || 0, 'Hidden from users'],
          ['Average Rate', `৳${Number(stats.average_rate || 0).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`, 'Against BDT'],
        ].map(([title, value, subtitle]) => (
          <div key={title} className="rounded-[14px] border border-slate-200 bg-white p-5 shadow-sm">
            <p className="text-sm text-slate-500">{title}</p>
            <p className="mt-2 text-2xl font-medium text-slate-950">{value}</p>
            <p className="mt-1 text-xs text-slate-400">{subtitle}</p>
          </div>
        ))}
      </div>

      {notice ? <div className="rounded-xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-700">{notice}</div> : null}

      <Panel title="Exchange Rate Management">
        <div className="mb-5 flex flex-col gap-3 lg:flex-row lg:items-end lg:justify-between">
          <div className="grid flex-1 gap-3 md:grid-cols-[1fr_180px]">
            <label className="block">
              <span className="mb-2 block text-sm font-medium text-slate-700">Search country or currency</span>
              <div className="flex h-12 items-center gap-3 rounded-xl border border-slate-200 bg-slate-50 px-4 focus-within:border-red-400 focus-within:bg-white">
                <Search size={16} className="text-slate-400" />
                <input value={query.search} onChange={(event) => updateQuery({ search: event.target.value })} placeholder="USD, Saudi Arabia, EUR..." className="h-full w-full bg-transparent text-sm outline-none" />
              </div>
            </label>
            <SelectField label="Status" value={query.status} onChange={(status) => updateQuery({ status })} options={['all', 'active', 'inactive']} />
          </div>
          <button type="button" onClick={() => setEditing({ ...exchangeRateFormDefaults })} className="inline-flex h-12 items-center justify-center gap-2 rounded-xl bg-red-600 px-5 text-sm font-medium text-white hover:bg-red-700">
            <Plus size={16} /> Add Rate
          </button>
        </div>

        {loading ? <LoadingBlock label="Loading exchange rates..." /> : error ? <ErrorBlock message={error} /> : (
          <div className="overflow-hidden rounded-[14px] border border-slate-200">
            <div className="hidden grid-cols-[1.6fr_1fr_1fr_1fr_120px] gap-4 bg-slate-50 px-4 py-3 text-xs font-medium uppercase tracking-[0.16em] text-slate-400 lg:grid">
              <span>Country</span>
              <span>Currency</span>
              <span>BDT Rate</span>
              <span>Status</span>
              <span className="text-right">Action</span>
            </div>
            <div className="divide-y divide-slate-100">
              {rates.length ? rates.map((rate) => (
                <div key={rate.id} className="grid gap-4 px-4 py-4 lg:grid-cols-[1.6fr_1fr_1fr_1fr_120px] lg:items-center">
                  <div className="flex items-center gap-3">
                    <span className="flex h-12 w-12 items-center justify-center rounded-xl bg-slate-100 text-2xl">{rate.country_flag || '🏳️'}</span>
                    <div>
                      <p className="font-medium text-slate-950">{rate.country_name}</p>
                      <p className="text-xs uppercase tracking-[0.16em] text-slate-400">{rate.country_code}</p>
                    </div>
                  </div>
                  <div>
                    <p className="font-medium text-slate-900">{rate.currency_code}</p>
                    <p className="text-sm text-slate-500">{rate.currency_name || 'Currency'}</p>
                  </div>
                  <div>
                    <p className="font-medium text-slate-950">৳{Number(rate.bdt_rate || 0).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 4 })}</p>
                    <p className="text-xs text-slate-500">Fee {formatMoney(rate.service_fee)}</p>
                  </div>
                  <StatusBadge status={rate.is_active ? 'active' : 'inactive'} />
                  <div className="flex justify-end gap-2">
                    <button onClick={() => setEditing(rate)} className="rounded-xl border border-slate-200 p-2 text-slate-600 hover:bg-slate-50"><Edit3 size={16} /></button>
                    <button onClick={() => deleteRate(rate)} className="rounded-xl border border-red-100 p-2 text-red-600 hover:bg-red-50"><Trash2 size={16} /></button>
                  </div>
                </div>
              )) : (
                <div className="p-8 text-center text-sm text-slate-500">No exchange rates found.</div>
              )}
            </div>
          </div>
        )}
      </Panel>

      {editing ? (
        <ExchangeRateModal
          rate={editing.id ? editing : null}
          initial={editing}
          onClose={() => setEditing(null)}
          onSaved={(message) => {
            setEditing(null);
            setNotice(message);
            loadRates();
          }}
        />
      ) : null}
    </div>
  );
}

function ExchangeRateModal({ rate, initial, onClose, onSaved }) {
  const [form, setForm] = useState({
    ...exchangeRateFormDefaults,
    ...initial,
    country_code: initial.country_code || '',
    currency_code: initial.currency_code || '',
    bdt_rate: initial.bdt_rate?.toString() || '',
    service_fee: initial.service_fee?.toString() || '0',
    sort_order: initial.sort_order?.toString() || '0',
    is_active: initial.is_active ?? true,
  });
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  async function submit(event) {
    event.preventDefault();
    setSaving(true);
    setError('');

    const payload = {
      ...form,
      country_code: form.country_code.toUpperCase(),
      currency_code: form.currency_code.toUpperCase(),
      service_fee: form.service_fee || '0',
      sort_order: form.sort_order || '0',
    };

    try {
      const response = rate?.id
        ? await api.put(`/admin/exchange-rates/${rate.id}`, payload)
        : await api.post('/admin/exchange-rates', payload);
      onSaved(response.data?.message || 'Exchange rate saved successfully.');
    } catch (apiError) {
      const errors = apiError.response?.data?.errors;
      setError(errors ? Object.values(errors).flat()[0] : (apiError.response?.data?.message || 'Could not save exchange rate.'));
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-slate-950/45 p-3 sm:items-center">
      <form onSubmit={submit} className="max-h-[92vh] w-full max-w-3xl overflow-y-auto rounded-[14px] border border-slate-200 bg-white p-5 shadow-sm">
        <div className="mb-5 flex items-start justify-between gap-4">
          <div>
            <p className="text-xs uppercase tracking-[0.22em] text-red-600">Rate Desk</p>
            <h3 className="mt-1 text-xl font-medium text-slate-950">{rate?.id ? 'Edit Exchange Rate' : 'Add Exchange Rate'}</h3>
          </div>
          <button type="button" onClick={onClose} className="rounded-xl border border-slate-200 p-2 text-slate-500 hover:bg-slate-50"><X size={18} /></button>
        </div>

        {error ? <div className="mb-4 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">{error}</div> : null}

        <div className="grid gap-4 md:grid-cols-2">
          <Field label="Country Name" value={form.country_name} onChange={(country_name) => setForm({ ...form, country_name })} required />
          <Field label="Country Code" value={form.country_code} onChange={(country_code) => setForm({ ...form, country_code })} required />
          <Field label="Flag Emoji" value={form.country_flag || ''} onChange={(country_flag) => setForm({ ...form, country_flag })} />
          <Field label="Currency Code" value={form.currency_code} onChange={(currency_code) => setForm({ ...form, currency_code })} required />
          <Field label="Currency Name" value={form.currency_name || ''} onChange={(currency_name) => setForm({ ...form, currency_name })} />
          <Field label="BDT Rate" type="number" value={form.bdt_rate} onChange={(bdt_rate) => setForm({ ...form, bdt_rate })} required />
          <Field label="Service Fee" type="number" value={form.service_fee} onChange={(service_fee) => setForm({ ...form, service_fee })} />
          <Field label="Delivery Time" value={form.delivery_time || ''} onChange={(delivery_time) => setForm({ ...form, delivery_time })} />
          <Field label="Sort Order" type="number" value={form.sort_order} onChange={(sort_order) => setForm({ ...form, sort_order })} />
          <ToggleField label="Visible in app" checked={Boolean(form.is_active)} onChange={(is_active) => setForm({ ...form, is_active })} />
        </div>

        <label className="mt-4 block">
          <span className="mb-2 block text-sm font-medium text-slate-700">Note</span>
          <textarea value={form.note || ''} onChange={(event) => setForm({ ...form, note: event.target.value })} className="min-h-24 w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm outline-none transition focus:border-red-400 focus:bg-white" />
        </label>

        <div className="mt-6 flex flex-col-reverse gap-3 sm:flex-row sm:justify-end">
          <button type="button" onClick={onClose} className="rounded-xl border border-slate-200 px-5 py-3 text-sm text-slate-600 hover:bg-slate-50">Cancel</button>
          <button disabled={saving} className="rounded-xl bg-red-600 px-5 py-3 text-sm font-medium text-white hover:bg-red-700 disabled:opacity-60">
            {saving ? 'Saving...' : 'Save Rate'}
          </button>
        </div>
      </form>
    </div>
  );
}

function SelectField({ label, value, onChange, options }) {
  return (
    <label className="block">
      <span className="mb-2 block text-sm font-medium text-slate-700">{label}</span>
      <select value={value} onChange={(event) => onChange(event.target.value)} className="h-12 w-full rounded-xl border border-slate-200 bg-slate-50 px-4 text-sm outline-none transition focus:border-red-400 focus:bg-white">
        {options.map((option) => <option key={option} value={option}>{option ? titleCase(option) : 'All'}</option>)}
      </select>
    </label>
  );
}

function ToggleField({ label, checked, onChange }) {
  return (
    <label className="flex items-center justify-between rounded-xl border border-slate-200 bg-slate-50 px-4 py-3">
      <span className="text-sm font-medium text-slate-700">{label}</span>
      <input type="checkbox" checked={checked} onChange={(event) => onChange(event.target.checked)} className="h-5 w-5 accent-red-600" />
    </label>
  );
}

function ProfilePage({ admin, onAdminChange }) {
  const [profile, setProfile] = useState({
    name: admin.name || '',
    email: admin.email || '',
    phone: admin.phone || '',
    address: admin.address || '',
    first_name: admin.first_name || '',
    last_name: admin.last_name || '',
    country_name: admin.country_name || '',
    country_code: admin.country_code || '',
  });
  const [password, setPassword] = useState({
    current_password: '',
    password: '',
    password_confirmation: '',
  });
  const [savingProfile, setSavingProfile] = useState(false);
  const [savingPassword, setSavingPassword] = useState(false);
  const [notice, setNotice] = useState('');
  const [error, setError] = useState('');

  async function submitProfile(event) {
    event.preventDefault();
    setSavingProfile(true);
    setError('');
    setNotice('');

    try {
      const response = await api.put('/admin/profile', profile);
      onAdminChange(response.data.admin);
      setNotice(response.data.message);
    } catch (apiError) {
      const errors = apiError.response?.data?.errors;
      setError(errors ? Object.values(errors).flat()[0] : (apiError.response?.data?.message || 'Could not update profile.'));
    } finally {
      setSavingProfile(false);
    }
  }

  async function submitPassword(event) {
    event.preventDefault();
    setSavingPassword(true);
    setError('');
    setNotice('');

    try {
      const response = await api.put('/admin/profile/password', password);
      setPassword({ current_password: '', password: '', password_confirmation: '' });
      setNotice(response.data.message);
    } catch (apiError) {
      const errors = apiError.response?.data?.errors;
      setError(errors ? Object.values(errors).flat()[0] : (apiError.response?.data?.message || 'Could not change password.'));
    } finally {
      setSavingPassword(false);
    }
  }

  return (
    <div className="space-y-6">
      <Panel title="Admin Profile">
        <div className="flex flex-col gap-5 sm:flex-row sm:items-center">
          <div className="flex h-20 w-20 items-center justify-center rounded-[14px] bg-red-600 text-2xl font-medium text-white">
            {admin.name?.slice(0, 2).toUpperCase()}
          </div>
          <div>
            <h2 className="text-2xl font-medium text-slate-950">{admin.name}</h2>
            <p className="mt-1 text-slate-500">{admin.email}</p>
            <p className="mt-3 text-sm text-slate-500">Phone: {admin.phone || 'Not set'} · Address: {admin.address || 'Not set'}</p>
          </div>
        </div>
      </Panel>

      {notice ? <div className="rounded-xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-700">{notice}</div> : null}
      {error ? <div className="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">{error}</div> : null}

      <form onSubmit={submitProfile}>
        <Panel title="Profile Information">
          <div className="grid gap-4 md:grid-cols-2">
            <Field label="Full Name" value={profile.name} onChange={(name) => setProfile({ ...profile, name })} required />
            <Field label="Email Address" type="email" value={profile.email} onChange={(email) => setProfile({ ...profile, email })} required />
            <Field label="Phone" value={profile.phone} onChange={(phone) => setProfile({ ...profile, phone })} />
            <Field label="Address" value={profile.address} onChange={(address) => setProfile({ ...profile, address })} />
            <Field label="First Name" value={profile.first_name} onChange={(first_name) => setProfile({ ...profile, first_name })} />
            <Field label="Last Name" value={profile.last_name} onChange={(last_name) => setProfile({ ...profile, last_name })} />
            <Field label="Country" value={profile.country_name} onChange={(country_name) => setProfile({ ...profile, country_name })} />
            <Field label="Country Code" value={profile.country_code} onChange={(country_code) => setProfile({ ...profile, country_code })} />
          </div>
          <button disabled={savingProfile} className="mt-5 rounded-xl bg-red-600 px-6 py-3 text-sm font-medium text-white hover:bg-red-700 disabled:opacity-60">
            {savingProfile ? 'Saving...' : 'Save Profile'}
          </button>
        </Panel>
      </form>

      <form onSubmit={submitPassword}>
        <Panel title="Change Password">
          <div className="grid gap-4 md:grid-cols-3">
            <Field label="Current Password" type="password" value={password.current_password} onChange={(current_password) => setPassword({ ...password, current_password })} required />
            <Field label="New Password" type="password" value={password.password} onChange={(nextPassword) => setPassword({ ...password, password: nextPassword })} required />
            <Field label="Confirm Password" type="password" value={password.password_confirmation} onChange={(password_confirmation) => setPassword({ ...password, password_confirmation })} required />
          </div>
          <button disabled={savingPassword} className="mt-5 rounded-xl border border-red-200 bg-red-50 px-6 py-3 text-sm font-medium text-red-700 hover:bg-red-100 disabled:opacity-60">
            {savingPassword ? 'Updating...' : 'Update Password'}
          </button>
        </Panel>
      </form>
    </div>
  );
}

function Field({ label, value, onChange, type = 'text', required = false }) {
  return (
    <label className="block">
      <span className="mb-2 block text-sm font-medium text-slate-700">{label}</span>
      <input required={required} type={type} value={value} onChange={(event) => onChange(event.target.value)} className="h-12 w-full rounded-xl border border-slate-200 bg-slate-50 px-4 text-sm outline-none transition focus:border-red-400 focus:bg-white" />
    </label>
  );
}

function Panel({ title, children }) {
  return (
    <section className="rounded-[14px] border border-slate-200 bg-white p-5 shadow-sm">
      <h3 className="mb-4 text-base font-medium text-slate-950">{title}</h3>
      {children}
    </section>
  );
}

function DataList({ rows, columns }) {
  if (!rows?.length) return <p className="text-sm text-slate-500">No records found.</p>;

  return (
    <div className="space-y-3">
      {rows.map((row) => (
        <div key={row.id} className="rounded-xl border border-slate-100 bg-slate-50 p-4">
          <div className="grid gap-2 sm:grid-cols-2">
            {columns.map((column) => (
              <p key={column} className="text-sm text-slate-600">
                <span className="mr-2 text-xs uppercase tracking-[0.15em] text-slate-400">{column.replace('_', ' ')}</span>
                {String(row[column] ?? '—')}
              </p>
            ))}
          </div>
        </div>
      ))}
    </div>
  );
}

function formatMoney(value) {
  return `BDT ${Number(value || 0).toLocaleString(undefined, { maximumFractionDigits: 2 })}`;
}

function formatDate(value) {
  if (!value) return 'Not processed';

  return new Date(value).toLocaleString(undefined, {
    dateStyle: 'medium',
    timeStyle: 'short',
  });
}

function titleCase(value) {
  return String(value || '')
    .replaceAll('_', ' ')
    .replace(/\b\w/g, (letter) => letter.toUpperCase());
}

let chatAudioContext = null;

function unlockChatAudio() {
  try {
    const AudioContextClass = window.AudioContext || window.webkitAudioContext;
    if (!AudioContextClass) return null;
    chatAudioContext ||= new AudioContextClass();
    if (chatAudioContext.state === 'suspended') {
      chatAudioContext.resume();
    }
    return chatAudioContext;
  } catch (_) {
    return null;
  }
}

function playChatTone(type) {
  try {
    const context = unlockChatAudio();
    if (!context) return;
    const oscillator = context.createOscillator();
    const gain = context.createGain();
    const map = {
      typing: [520, 0.035, 0.012],
      send: [720, 0.06, 0.018],
      receive: [420, 0.09, 0.025],
    };
    const [frequency, duration, volume] = map[type] || map.typing;

    oscillator.frequency.value = frequency;
    oscillator.type = 'sine';
    gain.gain.value = volume;
    oscillator.connect(gain);
    gain.connect(context.destination);
    oscillator.start();
    oscillator.stop(context.currentTime + duration);
  } catch (_) {
    // Browser may block audio before user interaction.
  }
}

function chatImageSrc(message) {
  if (!message?.id) return message?.attachment_api_url || message?.attachment_url || '';
  const base = (api.defaults.baseURL || '').replace(/\/$/, '');
  return `${base}/chat/messages/${message.id}/attachment`;
}

function hasChatImage(message) {
  return Boolean(message?.attachment_name || message?.attachment_url || message?.attachment_api_url);
}

function StatusBadge({ status }) {
  const classes = {
    active: 'border-emerald-200 bg-emerald-50 text-emerald-700',
    pending: 'border-amber-200 bg-amber-50 text-amber-700',
    processing: 'border-sky-200 bg-sky-50 text-sky-700',
    successful: 'border-emerald-200 bg-emerald-50 text-emerald-700',
    failed: 'border-red-200 bg-red-50 text-red-700',
    banned: 'border-red-200 bg-red-50 text-red-700',
    'chat banned': 'border-amber-200 bg-amber-50 text-amber-700',
    refunded: 'border-violet-200 bg-violet-50 text-violet-700',
    cancelled: 'border-slate-200 bg-slate-100 text-slate-600',
    inactive: 'border-slate-200 bg-slate-100 text-slate-600',
  };

  return <span className={`rounded-full border px-3 py-1 text-xs font-medium ${classes[status] || classes.inactive}`}>{titleCase(status)}</span>;
}

function LoadingBlock({ label }) {
  return (
    <div className="rounded-[14px] border border-slate-200 bg-white p-8 text-center text-sm text-slate-500 shadow-sm">
      {label}
    </div>
  );
}

function ErrorBlock({ message }) {
  return (
    <div className="rounded-[14px] border border-red-200 bg-red-50 p-6 text-sm text-red-700">
      <p className="font-medium text-red-800">Something went wrong</p>
      <p className="mt-2">{message}</p>
      <p className="mt-3 text-xs text-red-600">If this keeps happening, clear browser storage and confirm `VITE_API_BASE_URL` is correct.</p>
    </div>
  );
}
