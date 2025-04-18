// Fill out your copyright notice in the Description page of Project Settings.


#include "UI/SimpleHUD.h"
#include "SimpleGameInstance.h"

ASimpleHUD::ASimpleHUD()
{

}
void ASimpleHUD::PostInitializeComponents()
{
	Super::PostInitializeComponents();

	USimpleGameInstance* SimpleGameInstance = GetGameInstance<USimpleGameInstance>();

	if (SimpleGameInstance)
	{
		SimpleGameInstance->PrimaryLayoutAddWidgets(this);
	}
}
