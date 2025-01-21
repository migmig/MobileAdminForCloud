
import Foundation

// MARK: - SourcePipelineInfo
struct SourceProjectInfo :Codable{
   let result: SourcePipelineInfoResult
   init(){
       result = SourcePipelineInfoResult()
   }
}

// MARK: - SourcePipelineInfoResult
struct SourcePipelineInfoResult :Codable{
   let projectList: [SourceInfoProjectInfo]
    init(){
        projectList = []
    }
}

// MARK: - SourcePipelineInfoProjectList
struct SourceInfoProjectInfo :Codable,Hashable{
   let id: Int
   let name: String
    init(){
        id = 0
        name = ""
    }
    init(_ id:Int,_ name:String){
        self.id = id
        self.name = name
    }
}
