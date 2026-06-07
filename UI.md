Untuk **mobile app yang mau terasa “Apple-like”**, jangan bikin komponen full mentok layar seperti poster warung pulsa. Pakai **ruang napas**.

## Ukuran ideal

| Elemen                  |              Rekomendasi |
| ----------------------- | -----------------------: |
| Margin kiri-kanan layar |             **16–24 px** |
| Lebar card / section    | **100% parent - margin** |
| Border radius card      |             **16–24 px** |
| Padding dalam card      |             **16–20 px** |
| Jarak antar section     |             **16–24 px** |
| Button height           |             **48–56 px** |
| Input height            |             **48–52 px** |
| Icon size               |             **20–24 px** |
| Max width konten besar  |              **~430 px** |

## Formula aman

Untuk layar mobile:

```dart
padding: const EdgeInsets.symmetric(horizontal: 20)
```

Lalu card:

```dart
width: double.infinity,
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(20),
)
```

## Supaya terasa ala Apple

Gunakan pola ini:

```dart
Scaffold(
  backgroundColor: const Color(0xFFF5F5F7),
  body: SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
            ),
          ),

          SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hydration Goal'),
                SizedBox(height: 8),
                Text(
                  '1,250 ml',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
)
```

## Rule brutalnya

Kalau app kamu mau kelihatan mahal:

* **Jangan pakai margin 8 px** untuk layout utama.
* **Jangan semua elemen diberi border tebal.**
* **Jangan pakai terlalu banyak warna.**
* **Jangan card terlalu sempit.**
* **Jangan typography rata semua sama besar.**

Pakai ini sebagai default:

```dart
horizontalPadding = 20;
cardRadius = 24;
cardPadding = 18;
sectionGap = 20;
buttonHeight = 52;
```

Itu sudah cukup untuk bikin UI terlihat lebih “proposal Apple”, bukan “template tugas akhir yang disiksa deadline”.
