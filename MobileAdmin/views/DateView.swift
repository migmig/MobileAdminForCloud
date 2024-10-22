import SwiftUI

struct DateView: View {
    let date:Date
    
    // 날짜 형식을 "YYYY-MM-DD HH24:MI:SS" 형식으로 포맷하는 함수
    private var formatDate:String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss" // 날짜 형식을 설정
        return formatter.string(from: date) // 포맷된 문자열 반환
    }
    
    private var weekday:String{
        date.formatted(Date.FormatStyle()
            .weekday(.abbreviated))
        .localizedUppercase
    }
    
    private var day:String{
        date.formatted(Date.FormatStyle().day())
    }
    
    var body: some View {
        HStack {
            Text("\(formatDate)")
                .font(.headline)
        }
    }
} 
