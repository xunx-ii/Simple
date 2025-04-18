// Fill out your copyright notice in the Description page of Project Settings.


#include "UI/SimpleGameWidget.h"

USimpleGameWidget::USimpleGameWidget(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{

}

TOptional<FUIInputConfig> USimpleGameWidget::GetDesiredInputConfig() const
{
	switch (InputConfig)
	{
	case ESimpleWidgetInputMode::GameAndMenu:
		return FUIInputConfig(ECommonInputMode::All, GameMouseCaptureMode);
	case ESimpleWidgetInputMode::Game:
		return FUIInputConfig(ECommonInputMode::Game, GameMouseCaptureMode);
	case ESimpleWidgetInputMode::Menu:
		return FUIInputConfig(ECommonInputMode::Menu, EMouseCaptureMode::NoCapture);
	case ESimpleWidgetInputMode::Default:
	default:
		return TOptional<FUIInputConfig>();
	}
}
