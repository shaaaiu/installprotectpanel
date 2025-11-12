#!/bin/bash

REMOTE_PATH="/var/www/pterodactyl/app/Http/Controllers/Api/Client/Servers/ServerController.php"
TIMESTAMP=$(date -u +"%Y-%m-%d-%H-%M-%S")
BACKUP_PATH="${REMOTE_PATH}.bak_${TIMESTAMP}"

echo "🚀 Memasang proteksi Anti Akses Server Controller..."

# 🔹 Minta input ID admin
read -p "Masukkan ID Admin yang diizinkan untuk akses semua server: " ADMIN_ID

if [[ -z "$ADMIN_ID" ]]; then
  echo "❌ ID Admin tidak boleh kosong!"
  exit 1
fi

if ! [[ "$ADMIN_ID" =~ ^[0-9]+$ ]]; then
  echo "❌ ID Admin harus berupa angka!"
  exit 1
fi

if [ -f "$REMOTE_PATH" ]; then
  mv "$REMOTE_PATH" "$BACKUP_PATH"
  echo "📦 Backup file lama dibuat di $BACKUP_PATH"
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
     * Transform an individual server into a response that can be consumed by a
     * client using the API.
     */
    public function index(GetServerRequest \$request, Server \$server): array
    {
        // 🔒 Anti intip server orang lain (kecuali admin ID tertentu)
        \$authUser = Auth::user();

        if (\$authUser->id !== ${ADMIN_ID} && (int) \$server->owner_id !== (int) \$authUser->id) {
            abort(403, '@RYUUXIAO 𝗣𝗥𝗢𝗧𝗘𝗖𝗧 • 𝗔𝗸𝘀𝗲𝘀 𝗗𝗶 𝗧𝗼𝗹𝗮𝗸❌. 𝗛𝗮𝗻𝘆𝗮 𝗕𝗶𝘀𝗮 𝗠𝗲𝗹𝗶𝗵𝗮𝘁 𝗦𝗲𝗿𝘃𝗲𝗿 𝗠𝗶𝗹𝗶𝗸 𝗦𝗲𝗻𝗱𝗶𝗿𝗶.');
        }

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

echo "✅ Proteksi Anti Akses Server Controller berhasil dipasang!"
echo "📂 Lokasi file: $REMOTE_PATH"
echo "🗂️ Backup file lama: $BACKUP_PATH (jika sebelumnya ada)"
echo "🔒 Hanya Admin (ID ${ADMIN_ID}) yang bisa Akses semua server."
