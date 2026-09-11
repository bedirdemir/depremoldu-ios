import Foundation

struct AwarenessItem: Identifiable, Hashable {
    let id: String
    let title: String
    let summary: String?
    let source: String?
    let url: URL
    let actionTitle: String

    var systemImage: String {
        switch actionTitle {
        case "İzle": "play.rectangle"
        case "Görüntüle": "arrow.up.right.square"
        default: "book"
        }
    }
}

enum AwarenessContent {
    static let items: [AwarenessItem] = [
        AwarenessItem(
            id: "afad-during",
            title: "Deprem Anında Yapmanız Gerekenler",
            summary: "Depremlerde can ve mal kayıplarının artmasının en önemli nedenlerinden biri de sarsıntı sırasında kişilerin kendilerini nasıl koruyacaklarını ve ne yapmaları gerektiğini bilmemeleridir. Peki, deprem anında ne yapmanız gerekiyor?",
            source: "AFAD",
            url: URL(string: "https://www.afad.gov.tr/deprem-aninda-neler-yapmalisiniz")!,
            actionTitle: "Oku"
        ),
        AwarenessItem(
            id: "evrim-before-after",
            title: "Deprem Öncesinde ve Sonrasında Yapmanız Gerekenler",
            summary: "Panik yapmayın! Panik yapmaya başladıktan sonra hata yapmaya da başlarsınız! Binanızın önünden uzaklaşın! Dışarı çıktıktan sonra binanızın önünde beklemeyin.",
            source: "Evrim Ağacı",
            url: URL(string: "https://evrimagaci.org/deprem-oncesinde-sirasinda-ve-sonrasinda-neler-yapilmali-374")!,
            actionTitle: "Oku"
        ),
        AwarenessItem(
            id: "evrim-drop-cover-hold",
            title: "Çök-Kapan-Tutun Deprem Esnasında Nasıl Uygulanmalı?",
            summary: "Depremlerde yaşanan yaralanmaların en yaygın sebebi, sarsıntılar sırasında yüksek raflardan ve tavandan düşen/fırlayan cisimlerdir. Çök Kapan Tutun Yöntemi'nde, masa benzeri bir cismin altına girme önerisinin nedeni, düşen büyük bloklardan korunmak değil, düşen ve fırlayan cisimlerden (televizyon, lambalar, cam nesneler, kitaplar ve kitaplıklar gibi) korunmaktır.",
            source: "Evrim Ağacı",
            url: URL(string: "https://evrimagaci.org/hayat-ucgeni-vs-cok-kapan-tutun-deprem-sirasinda-hangi-yontem-uygulanmali-9505")!,
            actionTitle: "Oku"
        ),
        AwarenessItem(
            id: "youtube-bag",
            title: "Deprem Çantası Nasıl Hazırlanır?",
            summary: "Deprem ve afet hazırlık çantası nasıl olmalı?",
            source: "Murat Şen",
            url: URL(string: "https://www.youtube.com/watch?v=08gcIwc7h5g")!,
            actionTitle: "İzle"
        ),
        AwarenessItem(
            id: "evrim-what-is-earthquake",
            title: "Deprem Nedir? Neden Oluşur?",
            summary: "Deprem dediğimiz doğa olayı, yer kabuğundaki kırılmalar nedeniyle ortaya çıkan titreşimlerin dalgalar halinde yayılmasıdır. Bu olay, sanılanın aksine, yerkabuğunun hareketsiz değil de hareketli olduğunun bir göstergesi olup, kaotik süreçler içeren ve fizik bilimi başta olmak üzere diğer bilim dalları tarafından da incelenen bir olgudur.",
            source: "Evrim Ağacı",
            url: URL(string: "https://evrimagaci.org/deprem-nedir-depremlere-sebep-olan-doga-yasalari-ve-bu-yasalari-aciklayan-modeller-nelerdir-8936")!,
            actionTitle: "Oku"
        ),
        AwarenessItem(
            id: "youtube-kids",
            title: "Çocuklar İçin Deprem Bilgilendirmesi",
            summary: "Çocuklar için anlayabilecekleri bir dilde depremler, depremlerin oluşumu ve afet durumu hakkında genel bilgiler.",
            source: "Evrim Ağacı",
            url: URL(string: "https://www.youtube.com/watch?v=t0qdFLHZ-Kc")!,
            actionTitle: "İzle"
        ),
        AwarenessItem(
            id: "youtube-prediction",
            title: "Depremler Tahmin Edilebilir Mi?",
            summary: "Modern bilim ve teknolojimiz çerçevesinde depremleri önceden tahmin etmenin hiçbir yolu bulunmamaktadır. Deprem tahmini yaptığı iddia edilen kişi ve kurumlar tamamen istatistiki yalanlara ve hilelere başvurmaktadırlar.",
            source: "Evrim Ağacı",
            url: URL(string: "https://www.youtube.com/watch?v=uUakx0hRFGI")!,
            actionTitle: "İzle"
        ),
        AwarenessItem(
            id: "evrim-lights",
            title: "Deprem Işıkları Nedir?",
            summary: "Deprem ışıkları, depremler sırasında veya öncesinde görülebilen levha biçimli şimşekler, ışık topları, ışık akıntıları ve sabit parlamalar gibi olaylardır.",
            source: "Evrim Ağacı",
            url: URL(string: "https://evrimagaci.org/deprem-isiklari-depremler-sirasinda-neden-gokyuzunde-isiklar-beliriyor-13416")!,
            actionTitle: "Oku"
        ),
        AwarenessItem(
            id: "evrim-tsunami",
            title: "Tsunami Nedir? Türkiye'de Tsunami Olabilir mi?",
            summary: "Tsunamiler, yeryüzünde bilinen en yıkıcı doğa olaylarından birisidir. Gelgit dalgası olarak da bilinen \"tsunami\", genellikle depremler, volkanik patlamalar ve diğer su altı patlamaları etkisiyle çok miktarda suyun yer değiştirmesi sonucu okyanus, deniz ve büyük göllerde meydana gelebilen, sıra dışı yükseklikteki ve uzunluktaki dalgalara verilen isimdir.",
            source: "Evrim Ağacı",
            url: URL(string: "https://evrimagaci.org/tsunami-nedir-turkiyede-tsunami-olabilir-mi-eger-olursa-nasil-onlem-almaliyiz-ve-tsunami-sirasinda-neler-yapilmali-9496")!,
            actionTitle: "Oku"
        ),
        AwarenessItem(
            id: "evrim-nutrition",
            title: "Deprem Sonrası Beslenme: Doğal Afetlerde Beslenme Nasıl Olmalı?",
            summary: "Depremle mücadelede önceden alınmış tedbirler birçok insanın hayatının kurtulmasını sağlamaktadır. Önceden alınması gereken önlemler arasında gıda ve beslenmenin yeri büyüktür. Afet sonrasında yaşanan besin kıtlığı, dezavantajlı bireyler başta olmak üzere tüm afetzedelerde enerji ve besin ögesi yetersizliklerine bağlı sağlık sorunlarının görülmesine neden olmaktadır.",
            source: "Evrim Ağacı",
            url: URL(string: "https://evrimagaci.org/deprem-sonrasi-beslenme-dogal-afetlerde-beslenme-nasil-olmali-14014")!,
            actionTitle: "Oku"
        ),
        AwarenessItem(
            id: "evrim-richter",
            title: "Richter Ölçeği Nedir? Depremin Büyüklüğü, Şiddeti ve Gücü Arasındaki Fark Nedir?",
            summary: "Depremin büyüklüğü ile şiddeti arasında ne fark var? Bir deprem sırasında ne kadar enerji açığa çıkar?",
            source: "Evrim Ağacı",
            url: URL(string: "https://evrimagaci.org/richter-olcegi-nedir-depremin-buyuklugu-siddeti-ve-gucu-arasindaki-fark-nedir-2128")!,
            actionTitle: "Oku"
        ),
        AwarenessItem(
            id: "youtube-volcano",
            title: "Volkanik Patlama Nedir? Türkiye'deki Yanardağ Riski",
            summary: "Volkanlar, volkanik patlama ve Türkiye'deki volkan riski hakkında genel bilgiler.",
            source: "Evrim Ağacı",
            url: URL(string: "https://www.youtube.com/watch?v=9-CUv0ILeHo")!,
            actionTitle: "İzle"
        ),
        AwarenessItem(
            id: "afad-hazard-map",
            title: "Türkiye Deprem Tehlike Haritası (AFAD)",
            summary: nil,
            source: nil,
            url: URL(string: "https://www.afad.gov.tr/kurumlar/afad.gov.tr/39499/xfiles/deprem_haritasi.pdf")!,
            actionTitle: "Görüntüle"
        ),
        AwarenessItem(
            id: "mta-active-fault-map",
            title: "Türkiye Diri Fay Haritası (MTA)",
            summary: nil,
            source: nil,
            url: URL(string: "https://www.mta.gov.tr/en/sayfalar/maps/activefault/img/active_fault_1250000.jpg")!,
            actionTitle: "Görüntüle"
        ),
    ]
}
