package com.collectibleholdings.iterable_flutter

import androidx.annotation.NonNull

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.PluginRegistry.Registrar
import io.flutter.plugin.common.MethodChannel.Result
import com.iterable.iterableapi.*
import org.json.JSONObject
import org.json.JSONException
import java.util.Objects
import com.google.firebase.messaging.RemoteMessage.*
import com.google.firebase.FirebaseApp
import com.google.firebase.messaging.*

/** IterableFlutterPlugin */
class IterableFlutterPlugin : FlutterPlugin, MethodCallHandler {


  companion object {

    const val methodChannelName = "iterable_flutter"

    private var context: Context? = null

    @JvmStatic
    fun registerWith(registrar: Registrar) {
      context = registrar.activity().getApplication();
      val channel = MethodChannel(registrar.messenger(), methodChannelName)
      channel.setMethodCallHandler(IterableFlutterPlugin())
    }
  }

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    context = binding.applicationContext
    val channel = MethodChannel(binding.binaryMessenger, methodChannelName)
    channel.setMethodCallHandler(IterableFlutterPlugin())
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {

  }

  override fun onMethodCall(call: MethodCall, result: Result): Unit {
    when (call.method) {
      "initialize" -> {
        val apiKey = call.argument<String>("apiKey")
        val pushIntegrationName = call.argument<String>("pushIntegrationName")
        if (apiKey is String && pushIntegrationName is String) {
          initialize(apiKey, pushIntegrationName)
        }

        result.success("Initialize success..")
      }
      "setUserIdentity" -> {
        val userEmail = call.argument<String>("userEmail")
        val userId = call.argument<String>("userId")
        if (userEmail is String && userId is String) {
          setUserIdentity(userEmail, userId, call.argument<String>("firstName"))
        }
        result.success("SetUserIdentity success..")

      }
      "track" -> {
        val eventName = call.argument<String>("eventName")
        if (eventName is String) {
          track(eventName, call.argument<Map<String, Any>?>("params"))
        }
        result.success("Track success..")
      }
      "signOut" -> {
        signOut()

        result.success("SignOut success..")
      }
      "handleAndroidMessage" -> {
        val arguments = call.argument<Map<String?, Object?>>("message")
        if (arguments is Map<String?, Object?>) {
          handleAndroidMessage(arguments)
        }
      }
      else -> result.notImplemented()
    }
  }

  fun initialize(apiKey: String, pushIntergrationName: String) {
    val currentContext = context
    if (currentContext != null) {
      val config: IterableConfig = IterableConfig.Builder()
              .setPushIntegrationName(pushIntergrationName)
              .build()
      IterableApi.initialize(currentContext, apiKey, config)
    }
  }

  fun setUserIdentity(userEmail: String, userId: String, firstName: String?) {
    IterableApi.getInstance().setEmail(userEmail);

    IterableApi.getInstance().updateEmail(userEmail, IterableHelper.SuccessHandler() {
      val userIDobj = JSONObject()
      try {
        userIDobj.put("userId", userId)
      } catch (e: JSONException) {
        print("error")
      }
      IterableApi.getInstance().updateUser(userIDobj)
    }, IterableHelper.FailureHandler { reason, data ->
      val userIDobj = JSONObject()
      try {
        userIDobj.put("userId", userId)
      } catch (e: JSONException) {
        print("error")
      }
      IterableApi.getInstance().updateUser(userIDobj)
    });

    val datafields = JSONObject()

    if (firstName is String) {
      try {
        datafields.put("firstName", firstName)
      } catch (e: JSONException) {
        e.printStackTrace()
      }

      IterableApi.getInstance().updateUser(datafields)
    }

    IterableApi.getInstance().registerForPush();

  }

  fun track(eventName: String, params: Map<String, Any>?) {
    IterableApi.getInstance().registerForPush();

    IterableApi.getInstance().track(
            eventName,
            JSONObject(params)
    );
  }

  fun signOut() {
    IterableApi.getInstance().disablePush();
  }

  fun handleAndroidMessage(arguments: Map<String?, Object?>) {
    val currentContext = context;
    if (currentContext != null) {
      val message = getRemoteMessageForArguments(arguments);
      if (message != null) {
        IterableFirebaseMessagingService.handleMessageReceived(currentContext, message);
      }
    }
  }

  fun getRemoteMessageForArguments(messageMap: Map<String?, Object?>): RemoteMessage? {
    val to = Objects.requireNonNull(messageMap["to"]) as String
    val builder: RemoteMessage.Builder = Builder(to)
    val collapseKey = messageMap["collapseKey"] as String?
    val messageId = messageMap["messageId"] as String?
    val messageType = messageMap["messageType"] as String?
    val ttl: Int? = messageMap["ttl"] as Int?
    @SuppressWarnings("unchecked") val data = messageMap["data"] as Map<String, String>?
    if (collapseKey != null) {
      builder.setCollapseKey(collapseKey)
    }
    if (messageType != null) {
      builder.setMessageType(messageType)
    }
    if (messageId != null) {
      builder.setMessageId(messageId)
    }
    if (ttl != null) {
      builder.setTtl(ttl)
    }
    if (data != null) {
      builder.setData(data)
    }
    return builder.build()
  }
}
