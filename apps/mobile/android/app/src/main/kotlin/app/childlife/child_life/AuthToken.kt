package app.childlife.child_life

import android.content.Context
import com.google.android.gms.tasks.Tasks
import com.google.firebase.auth.FirebaseAuth
import java.util.concurrent.TimeUnit

/**
 * An ID token for the signed-in person with the app closed (upload worker, notification
 * answers, widgets). Android's Firebase Auth keeps the session itself — the one FlutterFire signs
 * in with — so native code asks it directly (iOS shares a refresh token through the keychain;
 * Android's SDK does not hand one out). Off the main thread only.
 */
object AuthToken {
    @Volatile private var emulatorSet = false

    fun idToken(context: Context, force: Boolean = false): String? {
        useEmulatorIfAsked(context)
        val user = FirebaseAuth.getInstance().currentUser ?: return null
        return runCatching { Tasks.await(user.getIdToken(force), 20, TimeUnit.SECONDS).token }.getOrNull()
    }

    /** Emulator builds: point a process the app did not start at the Auth emulator too. */
    private fun useEmulatorIfAsked(context: Context) {
        if (emulatorSet) return
        emulatorSet = true
        val snap = Glance.snapshot(context) ?: return
        val host = snap.optString("emulatorHost").takeIf { it.isNotEmpty() && !snap.isNull("emulatorHost") } ?: return
        // Already set when Flutter runs in this process.
        runCatching { FirebaseAuth.getInstance().useEmulator(host, 9099) }
    }
}
