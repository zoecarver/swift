// RUN: %target-swift-emit-ir -I %S/Inputs -enable-cxx-interop %s | %FileCheck %s

import Templates

// CHECK-LABEL: define {{.*}}void @"$s4main10basicTestsyyF"()
// CHECK: call i8* @{{_ZN12TemplatesNS121basicFunctionTemplateIlEEPKcT_|"\?\?\$basicFunctionTemplate@_J@TemplatesNS1@@YAPEBD_J@Z"}}(i{{64|32}} 0)
// CHECK: call i8* @{{_ZN12TemplatesNS118BasicClassTemplateIcE11basicMemberEv|"\?basicMember@\?\$BasicClassTemplate@D@TemplatesNS1@@QEAAPEBDXZ"}}(%"struct.TemplatesNS1::BasicClassTemplate"*
// CHECK: call i8* @{{_ZN12TemplatesNS112TemplatesNS229takesClassTemplateFromSiblingENS_12TemplatesNS318BasicClassTemplateIcEE|"\?takesClassTemplateFromSibling@TemplatesNS2@TemplatesNS1@@YAPEBDU\?\$BasicClassTemplate@D@TemplatesNS3@2@@Z"}}()
// CHECK: ret void
public func basicTests() {
  TemplatesNS1.basicFunctionTemplate(0)

  var basicClassTemplateInst = TemplatesNS1.BasicClassTemplateChar()
  basicClassTemplateInst.basicMember()

  TemplatesNS1.TemplatesNS2.takesClassTemplateFromSibling(TemplatesNS1.TemplatesNS2.BasicClassTemplateChar())
}

// CHECK-LABEL: define {{.*}}void @"$s4main22forwardDeclaredClassesyyF"()
// CHECK: call i8* @{{_ZN12TemplatesNS112TemplatesNS231forwardDeclaredFunctionTemplateIlEEPKcT_|"\?\?\$forwardDeclaredFunctionTemplate@_J@TemplatesNS2@TemplatesNS1@@YAPEBD_J@Z"}}(i{{64|32}} 0)
// CHECK: call i8* @{{_ZN12TemplatesNS112TemplatesNS228ForwardDeclaredClassTemplateIcE11basicMemberEv|"\?basicMember@\?\$ForwardDeclaredClassTemplate@D@TemplatesNS2@TemplatesNS1@@QEAAPEBDXZ"}}(%"struct.TemplatesNS1::TemplatesNS2::ForwardDeclaredClassTemplate"*
// CHECK: call i8* @{{_ZN12TemplatesNS112TemplatesNS240forwardDeclaredFunctionTemplateOutOfLineIlEEPKcT_|"\?\?\$forwardDeclaredFunctionTemplateOutOfLine@_J@TemplatesNS2@TemplatesNS1@@YAPEBD_J@Z"}}(i{{64|32}} 0)
// CHECK: call i8* @{{_ZN12TemplatesNS112TemplatesNS237ForwardDeclaredClassTemplateOutOfLineIcE11basicMemberEv|"\?basicMember@\?\$ForwardDeclaredClassTemplateOutOfLine@D@TemplatesNS2@TemplatesNS1@@QEAAPEBDXZ"}}(%"struct.TemplatesNS1::TemplatesNS2::ForwardDeclaredClassTemplateOutOfLine"*
// CHECK: ret void
public func forwardDeclaredClasses() {
  TemplatesNS1.TemplatesNS2.forwardDeclaredFunctionTemplate(0)

  var forwardDeclaredClassTemplateInst = TemplatesNS1.ForwardDeclaredClassTemplateChar()
  forwardDeclaredClassTemplateInst.basicMember()

  TemplatesNS1.TemplatesNS2.forwardDeclaredFunctionTemplateOutOfLine(0)

  var forwardDeclaredClassTemplateOutOfLineInst = ForwardDeclaredClassTemplateOutOfLineChar()
  forwardDeclaredClassTemplateOutOfLineInst.basicMember()
}
