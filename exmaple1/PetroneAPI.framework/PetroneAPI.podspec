Pod::Spec.new do |spec|
spec.name = "PetroneAPI"
spec.version = "1.0.0"
spec.summary = "BYROBOT PETRONE openAPI."
spec.homepage = "https://github.com/petrone/Documents"
spec.license = { type: 'MIT', file: 'LICENSE' }
spec.authors = { "BYROBOT" => 'dev@byrobot.co.kr' }

spec.platform = :ios, "10.0"
spec.requires_arc = true
spec.source = { git: "https://github.com/petrone/PetroneAPI.git", tag: "v#{spec.version}", submodules: true }
spec.source_files = "PetroneAPI/**/*.{h,swift}"
end
