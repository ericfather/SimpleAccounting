import Foundation
import SwiftUI

class ErrorService {
    static let shared = ErrorService()
    
    private init() {}
    
    func handleError(_ error: Error, in view: some View) -> some View {
        return view.alert(isPresented: .constant(true)) {
            Alert(
                title: Text("错误"),
                message: Text(getErrorMessage(error)),
                dismissButton: .default(Text("确定"))
            )
        }
    }
    
    func getErrorMessage(_ error: Error) -> String {
        if let dataError = error as? DataError {
            return dataError.errorDescription ?? "未知错误"
        } else if let nsError = error as? NSError {
            return nsError.localizedDescription
        } else {
            return error.localizedDescription
        }
    }
    
    func logError(_ error: Error, file: String = #file, line: Int = #line, function: String = #function) {
        let errorMessage = getErrorMessage(error)
        print("[ERROR] \(file):\(line) - \(function) - \(errorMessage)")
        
        // 这里可以添加更详细的日志记录，例如发送到远程日志服务
    }
    
    func handleErrorWithRetry(_ error: Error, retryAction: @escaping () -> Void) -> Alert {
        return Alert(
            title: Text("错误"),
            message: Text(getErrorMessage(error)),
            primaryButton: .default(Text("重试"), action: retryAction),
            secondaryButton: .cancel(Text("取消"))
        )
    }
}

// 扩展View，添加错误处理方法
extension View {
    func errorHandler(_ error: Binding<Error?>) -> some View {
        self.alert(isPresented: .constant(error.wrappedValue != nil)) {
            if let error = error.wrappedValue {
                return Alert(
                    title: Text("错误"),
                    message: Text(ErrorService.shared.getErrorMessage(error)),
                    dismissButton: .default(Text("确定")) {
                        error.wrappedValue = nil
                    }
                )
            } else {
                return Alert(title: Text("错误"))
            }
        }
    }
}
