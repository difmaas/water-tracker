# WTASLL adalah singkatan dari What This App Should Look Like. 
Ini adalah file yang berisikan poin poin bagaimana seharusnya aplikasi berjalan dari sudut pandang orang awam  yang tidak mengerti teknis, digunakan untuk mengendalikan perilaku AI coding agents dan mengurangi architectural drift serta rabbit hole generated code.

### App Short Description
Aplikasi ini adalah bagian dari penelitian yang berjudul 'Uji Efektivitas Aplikasi Pengingat Aktivitas Fisik sebagai Intervensi Gaya Hidup Sehat pada Remaja dengan Nomofobia (No Mobile Phone Phobia)'.

### App Philosophy
Aplikasi ini seharusnya lebih ramah pengguna, mudah digunakan dan dipahami, serta tidak terlalu rumit. 

### Who This App Is For
- Target utama : Remaja yang sering melupakan minum air putih karena sibuk menghabiskan waktu di depan smartphone, seperti bermain game, scrolling media sosial atau aktivitas lainnya.
- Target sekunder : Orang dewasa yang ingin menerapkan gaya hidup sehat dengan rajin minum air putih. 

### What User Should Feel  
Pengguna harus merasa aplikasi ini intuitif dan berhasil membangun kebiasaan sehat rutin minum air putih. User tidak boleh merasa sedang "dipantau". Aplikasi harus terasa seperti teman kecil yang membantu menjaga kebiasaan minum air.

### Core User Journey
Ideal session:
1. Buka aplikasi
2. Langsung lihat progress hari ini
3. Tap tombol tambah air
4. Progress bertambah
5. Tutup aplikasi
Target:
seluruh proses selesai kurang dari 15 detik.

### Screen-by-Screen Experience
1. Layar splash, berisikan logo aplikasi, pengenalan singkat terhadap aplikasi, meminta izin yang diperlukan, dalam hal ini meminta izin untuk mengirim notifikasi.
2. Layar 1 (Onboarding), berisikan informasi mengenai aplikasi, dan juga meminta input user yang diperlukan untuk menghasilkan perhitungan kebutuhan air putih user. Input berupa nama, tanggal lahir, jenis kelamin, riwayat penyakit, letak geografis, tinggi badan, berat badan, tingkat aktivitas, pilihan antara smart reminder atau interval reminder, jika interval reminder tampilkan pilihan 1jam,2jam,3jam, lalu rentang waktu pengingat. 
3. Layar 2 (Home) adalah tampilan utama aplikasi, berisikan informasi mengenai status konsumsi air user. Selain itu, terdapat juga tombol untuk menambah konsumsi air user. Di atas halaman terdapat header berisi informasi tanggal hari ini dan animasi singkat mengenai aktivitas manusia terkait penggunaan air. Selain itu terdapat fun fact singkat mengenai air putih. tombol batalkan, pilihan minum air 250, 500, ataupun ukuran manual.
4. Layar 3 (Riwayat) adalah tampilan riwayat aktivitas konsumsi air user, berisikan informasi mengenai status konsumsi air user dari hari ke hari, dan juga riwayat log untuk hari ini, jadi layar Home tidak terlalu ramai.
5. Layar 4 (Settings) adalah tampilan pengaturan aplikasi, berisikan informasi mengenai pengaturan aplikasi, seperti mengganti interval dan waktu pengingat, mengubah target konsumsi air putih, mengubah satuan konsumsi air putih.
6. Layar 5 (Edukasi) adalah tampilan mengenai informasi edukasi mengenai pentingnya minum air putih dan dampaknya bagi kesehatan user.

### Features
- Pengguna dapat mengubah waktu pengingat semisal dari pukul 07:00 sampai 21:00 tetapi pengingat tidak boleh mengakibatkan waktu tidur kurang dari 8 jam, selanjutnya set interval dapat disetting per 1jam,2jam,3jam.
- Interval pertama adalah 30 menit setelah pengguna bangun tidur, dihitung dari waktu pengingat, semisal jika pengguna mengatur waktu pengingat pukul 08:00 sampai 21:00, maka interval pertama adalah pukul 08:30 lalu lanjut berdasarkan interval yang disetting pengguna.
- Terdapat pilihan smart reminder dan interval reminder, smart reminder adalah reminder yang diset saat waktu untuk minum air lebih dibutuhkan, seperti 30 menit setelah bangun tidur, saat siang hari, dan juga menjelang waktu tidur.
- User bisa melakukan undo minum air maksimal selama 5 detik setelah tap tombol tambah air.Setelah 5 detik, undo tidak bisa dilakukan.

### Anti-Goals
Aplikasi ini tidak boleh:
- terasa seperti aplikasi gym hardcore
- terasa seperti dashboard medis
- membutuhkan terlalu banyak tap
- penuh popup
- penuh notifikasi
- memaksa user membuat akun
- membuat user merasa gagal

Jangan menambahkan:
- leaderboard
- feed sosial
- achievement berlebihan
- AI chatbot tidak penting
- fitur yang memperlambat logging

### UX Priorities
Aplikasi harus terasa:
- ringan
- cepat dibuka
- responsif
- minim loading

User harus bisa:
- membuka app dengan cepat
- log air tanpa delay
- memakai app bahkan tanpa internet

Offline-first lebih penting daripada sinkronisasi cloud kompleks.

### Things The App Must Never Become
Aplikasi ini tidak boleh berubah menjadi:
- super app kesehatan
- social media habit tracker
- aplikasi produktivitas kompleks
- aplikasi dengan 100 pengaturan

Jika ada keputusan desain:
pilih opsi yang lebih sederhana.

### Performance
- Aplikasi harus terasa sangat ringan dan responsif.
- Waktu buka aplikasi kurang dari 2 detik.
-animasi transisi antar layar harus halus tanpa jeda.
- aplikasi bisa digunakan tanpa internet connection. Sync data dapat dilakukan secara offline dan diupload saat sudah ada koneksi internet.
