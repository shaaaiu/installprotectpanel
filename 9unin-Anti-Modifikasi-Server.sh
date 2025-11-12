#!/bin/bash

REMOTE_PATH="/var/www/pterodactyl/app/Services/Servers/DetailsModificationService.php"

echo "🚀 Menghapus proteksi Anti Modifikasi Detail Server..."

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

# 🔹 Konfirmasi
read -p "Konfirmasi ulang ID Admin (${ADMIN_ID}) untuk melanjutkan uninstall proteksi (y/n)? " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "❌ Pembatalan uninstall proteksi."
  exit 1
fi

mkdir -p "$(dirname "$REMOTE_PATH")"
chmod 755 "$(dirname "$REMOTE_PATH")"

cat > "$REMOTE_PATH" << EOF
<?php

namespace Pterodactyl\Services\Servers;

use Illuminate\Support\Arr;
use Illuminate\Support\Facades\Auth;
use Pterodactyl\Models\Server;
use Illuminate\Database\ConnectionInterface;
use Pterodactyl\Traits\Services\ReturnsUpdatedModels;
use Pterodactyl\Repositories\Wings\DaemonServerRepository;
use Pterodactyl\Exceptions\Http\Connection\DaemonConnectionException;

class DetailsModificationService
{
    use ReturnsUpdatedModels;

    /**
     * DetailsModificationService constructor.
     */
    public function __construct(
        private ConnectionInterface \$connection,
        private DaemonServerRepository \$serverRepository
    ) {}

    /**
     * Update the details for a single server instance.
     *
     * @throws \\Throwable
     */
    public function handle(Server \$server, array \$data): Server
    {
        // 🔒 Hanya admin ID tertentu yang boleh uninstall proteksi
        \$user = Auth::user();
        if (!\$user || \$user->id !== ${ADMIN_ID}) {
            abort(403, '🚫 Anda tidak memiliki izin untuk menghapus proteksi modifikasi detail server.');
        }

        return \$this->connection->transaction(function () use (\$data, \$server) {
            \$owner = \$server->owner_id;

            \$server->forceFill([
                'external_id' => Arr::get(\$data, 'external_id'),
                'owner_id' => Arr::get(\$data, 'owner_id'),
                'name' => Arr::get(\$data, 'name'),
                'description' => Arr::get(\$data, 'description') ?? '',
            ])->saveOrFail();

            // Jika owner berubah, revoke token lama
            if (\$server->owner_id !== \$owner) {
                try {
                    \$this->serverRepository->setServer(\$server)->revokeUserJTI(\$owner);
                } catch (DaemonConnectionException \$exception) {
                    // Abaikan error jika Wings offline
                }
            }

            return \$server;
        });
    }
}
EOF

chmod 644 "$REMOTE_PATH"

echo "✅ Menghapus Proteksi Anti Modifikasi Detail Server berhasil!"
echo "📂 Lokasi file: $REMOTE_PATH"
echo "🔒 Hanya Admin (ID ${ADMIN_ID}) yang berhak menjalankan uninstall ini."
