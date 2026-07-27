import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var showOTPView = false
    @FocusState private var emailFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.loginBackground.ignoresSafeArea()
                    .allowsHitTesting(false)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Theme.primary.opacity(0.55), Theme.primary.opacity(0)],
                            center: .center, startRadius: 0, endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)
                    .offset(x: 120, y: -260)
                    .allowsHitTesting(false)

                VStack(alignment: .leading, spacing: 0) {
                    Text("Expense Tracker")
                        .font(Theme.Font.ui(19, weight: .bold))
                        .foregroundColor(.white)
                        .tracking(1.5)
                        .padding(.bottom, 44)

                    Text("Know exactly\nwhere it goes.")
                        .font(Theme.Font.ui(32, weight: .bold))
                        .foregroundColor(.white)
                        .lineSpacing(4)
                        .padding(.bottom, 14)

                    Text("Track your daily expenses, organized by month, summarized automatically.")
                        .font(Theme.Font.ui(15))
                        .foregroundColor(.white.opacity(0.62))
                        .lineSpacing(4)

                    Spacer()

                    VStack(spacing: 16) {
                        // Wrapping the tap-to-focus gesture around the TextField, rather
                        // than attaching it to the TextField itself, is required — SwiftUI's
                        // own editing gesture on the control silently swallows a same-view
                        // .onTapGesture without ever engaging (confirmed empirically: an
                        // identical gesture one level up in the tree fires reliably).
                        ZStack {
                            TextField("Email", text: $email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .focused($emailFocused)
                                .padding(.horizontal, 16)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(emailFocused ? Theme.primary : .clear, lineWidth: 2))
                        .contentShape(Rectangle())
                        .onTapGesture { emailFocused = true }

                        Button(action: {
                            authManager.signUpWithOTP(email: email)
                            showOTPView = true
                        }) {
                            Group {
                                if authManager.isLoading {
                                    ProgressView().tint(Theme.textPrimary)
                                } else {
                                    Text("Send Code")
                                        .font(Theme.Font.ui(15, weight: .semibold))
                                        .foregroundColor(Theme.textPrimary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                        .disabled(email.isEmpty || authManager.isLoading)
                        .opacity(email.isEmpty ? 0.5 : 1)

                        if let error = authManager.errorMessage {
                            Text(error)
                                .font(Theme.Font.ui(12))
                                .foregroundColor(.red)
                        }

                        Text("By continuing you agree to the Terms & Privacy Policy")
                            .font(Theme.Font.ui(11))
                            .foregroundColor(.white.opacity(0.35))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 8)
                    }

                    // A trailing flexible Spacer is required here, not just cosmetic —
                    // without flexible space on both sides of the TextField, tap
                    // hit-testing silently stops reaching it (confirmed empirically).
                    // Bounded so the bottom block still sits near the bottom, matching
                    // the mockup, rather than drifting to vertical center.
                    Spacer().frame(maxHeight: 40)
                }
                .padding(.horizontal, 28)
                .padding(.top, 70)
                .padding(.bottom, 40)
            }
            .navigationDestination(isPresented: $showOTPView) {
                OTPView(email: email)
            }
        }
    }
}

struct OTPView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var otpCode = ""
    @FocusState private var otpFocused: Bool
    let email: String
    private let codeLength = 8

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(Theme.surface)
                    .overlay(Circle().stroke(Theme.border, lineWidth: 1))
                    .clipShape(Circle())
            }
            .padding(.bottom, 22)

            Text("Enter the code")
                .font(Theme.Font.ui(22, weight: .bold))
                .foregroundColor(Theme.textPrimary)
                .padding(.bottom, 6)

            Text("We sent an \(codeLength)-digit code to \(email)")
                .font(Theme.Font.ui(14))
                .foregroundColor(Theme.textSecondary)

            ZStack {
                TextField("", text: $otpCode)
                    .keyboardType(.numberPad)
                    .focused($otpFocused)
                    .opacity(0.01)
                    .onChange(of: otpCode) { _, newValue in
                        let digitsOnly = newValue.filter(\.isNumber)
                        otpCode = String(digitsOnly.prefix(codeLength))
                    }

                HStack(spacing: 6) {
                    ForEach(0..<codeLength, id: \.self) { index in
                        let chars = Array(otpCode)
                        let char = index < chars.count ? String(chars[index]) : ""
                        Text(char)
                            .font(Theme.Font.mono(20, weight: .medium))
                            .foregroundColor(Theme.textPrimary)
                            .frame(width: 36, height: 54)
                            .background(Theme.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(otpFocused && index == chars.count ? Theme.primary : Theme.border, lineWidth: 1.5)
                            )
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { otpFocused = true }
            }
            .padding(.top, 32)

            Button(action: {
                authManager.verifyOTP(email: email, token: otpCode)
            }) {
                Group {
                    if authManager.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Verify & continue")
                            .font(Theme.Font.ui(15, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(otpCode.count == codeLength ? Theme.primary : Theme.primary.opacity(0.4))
                .cornerRadius(12)
            }
            .disabled(otpCode.count != codeLength || authManager.isLoading)
            .padding(.top, 28)

            if let error = authManager.errorMessage {
                Text(error)
                    .font(Theme.Font.ui(13))
                    .foregroundColor(.red)
                    .padding(.top, 12)
            }

            HStack(spacing: 4) {
                Text("Didn't get a code?")
                    .foregroundColor(Theme.textSecondary)
                Button("Resend") {
                    authManager.signUpWithOTP(email: email)
                }
                .foregroundColor(Theme.primary)
                .fontWeight(.semibold)
            }
            .font(Theme.Font.ui(13))
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 18)

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 64)
        .padding(.bottom, 32)
        .background(Theme.surface.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .onAppear { otpFocused = true }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager())
}
