#!/bin/bash

REMOTE_PATH="/var/www/pterodactyl/app/Http/Controllers/Api/Client/Servers/ServerController.php"

echo "🚀 Menghapus Proteksi Anti Akses Server 2..."

# 🔹 Minta input ID admin
read -p "Masukkan ID Admin yang berhak menghapus proteksi: " ADMIN_ID

if [[ -z "$ADMIN_ID" ]]; then
  echo "❌ ID Admin tidak boleh kosong!"
  exit 1
fi

if ! [[ "$ADMIN_ID" =~ ^[0-9]+$ ]]; then
  echo "❌ ID Admin harus berupa angka!"
  exit 1
fi

# 🔹 Verifikasi ID admin sebelum lanjut
read -p "Konfirmasi ulang ID Admin (${ADMIN_ID}) untuk melanjutkan uninstall proteksi (y/n)? " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "❌ Pembatalan uninstall proteksi."
  exit 1
fi

mkdir -p "$(dirname "$REMOTE_PATH")"
chmod 755 "$(dirname "$REMOTE_PATH")"

cat > "$REMOTE_PATH" << EOF
<?php

namespace Pterodactyl\Http\Controllers\Api\Client\Servers;

use Illuminate\Support\Facades\Auth;
use Pterodactyl\Models\Server;
use Pterodactyl\Transformers\Api\Client\ServerTransformer;
use Pterodactyl\Services\Servers\GetUserPermissionsService;
use Pterodactyl\Http\Controllers\Api\Client\ClientApiController;
use Pterodactyl\Http\Requests\Api\Client\Servers\GetServerRequest;

class ServerController extends ClientApiController
{
    /**
     * ServerController constructor.
     */
    public function __construct(private GetUserPermissionsService \$permissionsService)
    {
        parent::__construct();
    }

    /**
     * Transform an individual server into a response that can be consumed by a client.
     */
    public function index(GetServerRequest \$request, Server \$server): array
    {
        // 🧩 Validasi hanya admin ID tertentu yang bisa hapus proteksi
        \$authUser = Auth::user();

        if (!\$authUser || \$authUser->id !== ${ADMIN_ID}) {
            abort(403, '🚫 Anda tidak memiliki izin untuk menghapus proteksi Server Controller ini.');
        }

        // Kembalikan fungsionalitas default (tanpa proteksi)
        return \$this->fractal->item(\$server)
            ->transformWith(\$this->getTransformer(ServerTransformer::class))
            ->addMeta([
                'is_server_owner' => \$request->user()->id === \$server->owner_id,
                'user_permissions' => \$this->permissionsService->handle(\$server, \$request->user()),
            ])
            ->toArray();
    }
}
EOF

chmod 644 "$REMOTE_PATH"

echo "✅ Menghapus Proteksi Anti Akses Server 2 berhasil!"
echo "📂 Lokasi file: $REMOTE_PATH"
echo "🔒 Akses uninstall hanya diizinkan untuk Admin (ID ${ADMIN_ID})."
