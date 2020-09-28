/*
 * Copyright 2020 ZUP IT SERVICOS EM TECNOLOGIA E INOVACAO SA
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package br.com.zup.beagle.sample.actions

import android.view.View
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleObserver
import androidx.lifecycle.OnLifecycleEvent
import br.com.zup.beagle.android.action.Action
import br.com.zup.beagle.android.utils.handleEvent
import br.com.zup.beagle.android.widget.RootView
import br.com.zup.beagle.annotation.RegisterAction
import br.com.zup.beagle.sample.ClickInterface
import br.com.zup.beagle.sample.MainActivity
import br.com.zup.beagle.sample.TestDialogFragment

@RegisterAction
class CustomAndroidAction : Action {

    override fun execute(rootView: RootView, origin: View) {
        val testDialog = TestDialogFragment.newInstance(object : ClickInterface{
            override fun clickOk() {
                handleEvent(rootView = rootView,origin = origin, actions = listOf())
            }

        })
        rootView.getLifecycleOwner().lifecycle.addObserver(
            object : LifecycleObserver {
                @OnLifecycleEvent(Lifecycle.Event.ON_PAUSE)
                fun onPause() {
                    testDialog.dismiss()
                }
            }
        )
        testDialog.show((rootView.getContext() as MainActivity).supportFragmentManager, "TAG")

    }
}
