import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var showOTPView = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 16) {
                    Text("Expense Tracker")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Track your daily expenses")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                Spacer()

                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    Button(action: {
                        authManager.signUpWithOTP(email: email)
                        showOTPView = true
                    }) {
                        if authManager.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(12)
                        } else {
                            Text("Send OTP")
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .disabled(email.isEmpty || authManager.isLoading)
                }

                if let error = authManager.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Spacer()
            }
            .padding()
            .navigationDestination(isPresented: $showOTPView) {
                OTPView(email: email)
            }
        }
    }
}

struct OTPView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var otpCode = ""
    let email: String

    var body: some View {
        VStack(spacing: 24) {
            Text("Enter OTP")
                .font(.title2)
                .fontWeight(.bold)

            Text("We sent a code to \(email)")
                .foregroundColor(.gray)

            TextField("OTP Code", text: $otpCode)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)

            Button(action: {
                authManager.verifyOTP(email: email, token: otpCode)
            }) {
                if authManager.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(12)
                } else {
                    Text("Verify")
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .disabled(otpCode.isEmpty || authManager.isLoading)

            if let error = authManager.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Spacer()
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager())
}
