//
//  Mansion.swift
//  Orot
//
//  28수(宿). 동방 청룡 → 북방 현무 → 서방 백호 → 남방 주작 순서로 채웁니다.
//  별 수는 전통 기준(문헌마다 조금씩 다름)이고, 별 배치는 시안용 모양이라
//  실제 천상열차분야지도 좌표로 바꾸어야 합니다. 수마다 붙인 설명도 감수가 필요합니다.
//

import CoreGraphics

// MARK: - Direction
enum MansionDirection: Int, CaseIterable {
    case east, north, west, south

    var name: String {
        switch self {
        case .east: return "동방 청룡"
        case .north: return "북방 현무"
        case .west: return "서방 백호"
        case .south: return "남방 주작"
        }
    }
}

// MARK: - Mansion
struct Mansion: Identifiable, Hashable {
    let index: Int
    let hanja: String
    let korean: String
    let starCount: Int
    let meaning: String
    /// 별자리 중심 기준 상대 좌표 (단위: pt, 간격 약 14)
    let points: [CGPoint]

    var id: Int { index }
    var direction: MansionDirection { MansionDirection(rawValue: index / 7)! }
    /// 방위 안에서 몇 번째 수인지 (1~7)
    var orderInDirection: Int { index % 7 + 1 }
    /// "두(斗)"
    var label: String { "\(korean)(\(hanja))" }
    /// 연결선: 순서대로 잇습니다.
    var segments: [(Int, Int)] { (0..<max(0, starCount - 1)).map { ($0, $0 + 1) } }

    static func == (lhs: Mansion, rhs: Mansion) -> Bool { lhs.index == rhs.index }
    func hash(into hasher: inout Hasher) { hasher.combine(index) }
}

// MARK: - Catalog
extension Mansion {
    static let all: [Mansion] = raw.enumerated().map { i, item in
        Mansion(index: i, hanja: item.0, korean: item.1, starCount: item.2, meaning: item.3, points: shape(seed: Int64(101 + i * 7), count: item.2))
    }

    static let totalStars = all.reduce(0) { $0 + $1.starCount }

    /// 시안과 같은 임의 모양: 14pt 간격으로 방향을 조금씩 틀며 이어 갑니다.
    private static func shape(seed: Int64, count: Int) -> [CGPoint] {
        var r = SeededRandom(seed: seed)
        var x = 0.0, y = 0.0, a = r.next() * 6.28
        var pts = [CGPoint.zero]
        for _ in 1..<max(1, count) {
            a += (r.next() - 0.5) * 1.6
            x += cos(a) * 14
            y += sin(a) * 14
            pts.append(CGPoint(x: x, y: y))
        }
        let xs = pts.map(\.x), ys = pts.map(\.y)
        let cx = (xs.min()! + xs.max()!) / 2, cy = (ys.min()! + ys.max()!) / 2
        return pts.map { CGPoint(x: $0.x - cx, y: $0.y - cy) }
    }

    private static let raw: [(String, String, Int, String)] = [
        ("角", "각", 2, "용의 뿔. 봄밤 동쪽 하늘에서 가장 먼저 떠오르는 수예요."),
        ("亢", "항", 4, "용의 목. 뿔 뒤를 잇는 네 별이에요."),
        ("氐", "저", 4, "용의 가슴, 근본을 뜻해요."),
        ("房", "방", 4, "용의 배이자 방(房). 하늘의 마구간으로도 불렸어요."),
        ("心", "심", 3, "용의 심장. 가운데 붉은 별이 유난히 밝아요."),
        ("尾", "미", 9, "용의 꼬리. 아홉 별이 굽이쳐 이어져요."),
        ("箕", "기", 4, "곡식을 고르는 키 모양이에요. 바람을 부른다고 여겼어요."),
        ("斗", "두", 6, "남두육성. 남쪽 하늘의 국자 모양 여섯 별이에요."),
        ("牛", "우", 6, "소. 견우와 이어지는 수예요."),
        ("女", "여", 4, "베 짜는 여인. 직녀와 이어지는 수예요."),
        ("虛", "허", 2, "빈 터. 고요하고 텅 빈 하늘이에요."),
        ("危", "위", 3, "높은 지붕마루. 지붕 꼭대기처럼 솟은 세 별이에요."),
        ("室", "실", 2, "집. 하늘의 궁궐을 뜻해요."),
        ("壁", "벽", 2, "담, 그리고 책을 두는 곳. 학문의 별이에요."),
        ("奎", "규", 16, "열여섯 별이 둥글게 모인 수. 문장(文章)의 별로 불렸어요."),
        ("婁", "루", 3, "모여서 기른다는 뜻의 세 별이에요."),
        ("胃", "위", 3, "하늘의 곳간이에요."),
        ("昴", "묘", 7, "좀생이별. 작은 별들이 한데 모여 있어요."),
        ("畢", "필", 8, "토끼를 잡는 그물 모양이에요."),
        ("觜", "자", 3, "호랑이의 부리. 아주 작은 세 별이에요."),
        ("參", "삼", 10, "세 별이 나란히 놓인 겨울 하늘의 수예요."),
        ("井", "정", 8, "우물. 여름 남쪽 하늘의 첫 수예요."),
        ("鬼", "귀", 4, "혼령. 가운데 뿌연 별무리가 있어요."),
        ("柳", "류", 8, "버드나무. 주작의 부리라고도 해요."),
        ("星", "성", 7, "별. 주작의 목에 해당해요."),
        ("張", "장", 6, "활을 펼친 모양, 주작의 모이주머니예요."),
        ("翼", "익", 22, "날개. 스물두 별로 가장 많아요."),
        ("軫", "진", 4, "수레. 바람을 맡는 네 별이에요."),
    ]
}

// MARK: - Korean Ordinal
enum KoreanOrdinal {
    private static let natives = ["첫", "두", "세", "네", "다섯", "여섯", "일곱", "여덟", "아홉", "열"]

    /// 1 → "첫", 4 → "네", 12 → "12"
    static func word(_ n: Int) -> String {
        (1...natives.count).contains(n) ? natives[n - 1] : "\(n)"
    }

    /// 개수: 1 → "한", 2 → "두", 12 → "12"
    static func count(_ n: Int) -> String {
        n == 1 ? "한" : word(n)
    }
}
